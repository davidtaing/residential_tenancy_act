defmodule ResidentialTenancyAct.Chatbot do
  @moduledoc """
  A module for interacting with the chatbot.
  """

  require Logger

  alias ResidentialTenancyAct.Acts.RTASections
  alias ResidentialTenancyAct.Chat.{Messages, TokenHistory}
  alias ResidentialTenancyAct.ChatStateServer
  alias ResidentialTenancyAct.LLM
  alias ResidentialTenancyAct.LLM.Prompts
  alias ResidentialTenancyAct.Accounts.User

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

    {:ok, %{message: last_message, context: context, response: response_message}}
  end

  def perform_rag_search(message) do
    text = message.content
    {:ok, embeddings, _token_count} = LLM.generate_embeddings(text)
    sections = RTASections.similarity_search(:nsw, embeddings)

    Prompts.format_sections_context(sections)
  end

  def get_conversation_title(_message) do
    nil
  end
end
