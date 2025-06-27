defmodule ResidentialTenancyAct.Chatbot do
  @moduledoc """
  A module for interacting with the chatbot.
  """

  require Ash.Query
  require Logger

  alias ResidentialTenancyAct.Acts.RTASections
  alias ResidentialTenancyAct.Chat.{Messages, TokenHistory, Conversations}
  alias ResidentialTenancyAct.ChatStateServer
  alias ResidentialTenancyAct.LLM
  alias ResidentialTenancyAct.LLM.Prompts
  alias ResidentialTenancyAct.Accounts.User
  alias ResidentialTenancyAct.LLM.AWSNovaRequest.{Message, TextContent}

  @spec generate_response(pid(), list(Messages.t()), User.t(), map()) ::
          {:ok, %{message: Messages.t(), context: String.t(), response: Messages.t()}}
  def generate_response(chat_server_pid, messages, current_user, metadata \\ %{}) do
    last_message = List.last(messages)
    user_prompt = last_message.content

    Logger.info("Chatbot: Searching for relevant sections",
      conversation_id: metadata.conversation_id
    )

    ChatStateServer.change_to_searching(chat_server_pid, user_prompt)

    # perform RAG search
    context = perform_rag_search(last_message)
    ChatStateServer.change_to_generating(chat_server_pid, context)

    Logger.info("Chatbot: Found relevant sections")

    # build master prompt with context
    master_prompt = Prompts.build_rta_prompt(user_prompt, context)

    ChatStateServer.change_to_generating(chat_server_pid, master_prompt)

    previous_messages =
      messages
      |> Enum.drop(-1)
      |> Enum.take(-4)

    last_message_with_master_prompt = %Messages{last_message | content: master_prompt}

    messages =
      (previous_messages ++ [last_message_with_master_prompt])
      |> Messages.to_aws_messages()

    # Invoke LLM
    {:ok, %{text: response, usage: usage}} = LLM.generate_text_response(messages, metadata)

    Logger.info("Chatbot: LLM response generated")

    # Update token history
    token_history = %{
      conversation_id: last_message.conversation_id,
      input_tokens: usage["inputTokens"],
      output_tokens: usage["outputTokens"]
    }

    token_history =
      TokenHistory
      |> Ash.Changeset.for_create(:create, token_history, actor: current_user)
      |> Ash.create!()

    Logger.info("Chatbot: Token History Updated", token_history: token_history)

    # Create response message
    response_message =
      Messages
      |> Ash.Changeset.for_create(
        :create,
        %{
          content: response,
          role: :assistant,
          conversation_id: last_message.conversation_id
        },
        actor: current_user
      )
      |> Ash.create!()

    Logger.info("Chatbot: Response message created")

    ChatStateServer.change_to_responding(chat_server_pid, response_message)

    Conversations.touch(last_message.conversation_id)

    :ok
  end

  @spec perform_rag_search(Messages.t()) :: String.t()
  def perform_rag_search(message) do
    text = message.content
    {:ok, embeddings, _token_count} = LLM.generate_embeddings(text)
    sections = RTASections.similarity_search(:nsw, embeddings)

    Prompts.format_sections_context(sections)
  end

  @spec generate_title(String.t(), User.t()) :: Conversations.t()
  def generate_title(conversation_id, current_user) do
    message =
      Messages
      |> Ash.Query.new()
      |> Ash.Query.filter(conversation_id: conversation_id)
      |> Ash.Query.sort(created_at: :asc)
      |> Ash.Query.limit(1)
      |> Ash.read!(actor: current_user)
      |> hd()

    content = message.content
      |> Prompts.build_title_prompt()

    payload =
      [
        %Message{
          role: :user,
          content: [
            %TextContent{text: content}
          ]
        }
      ]


    {:ok, %{text: response, usage: usage}} = LLM.generate_text_response(payload)

    response = response |> String.replace("\"", "")

    # Update token history
    token_history = %{
      conversation_id: conversation_id,
      input_tokens: usage["inputTokens"],
      output_tokens: usage["outputTokens"]
    }

    token_history =
      TokenHistory
      |> Ash.Changeset.for_create(:create, token_history, actor: current_user)
      |> Ash.create!()

    Logger.info("Chatbot: Token History Updated", token_history: token_history)

    conversation = Conversations
    |> Ash.get!(conversation_id, actor: current_user)
    |> Ash.Changeset.for_update(:update, %{title: response}, actor: current_user)
    |> Ash.update!()

    conversation
  end
end
