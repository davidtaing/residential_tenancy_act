defmodule ResidentialTenancyActWeb.ChatLive do
  use ResidentialTenancyActWeb, :live_view

  on_mount {ResidentialTenancyActWeb.LiveUserAuth, :live_user_required}

  require Ash.Query
  require Logger

  import ResidentialTenancyActWeb.MarkdownHelper, only: [render_markdown: 1]

  alias ResidentialTenancyActWeb.ChatLive.SidebarComponent
  alias ResidentialTenancyAct.Chat.Conversations
  alias ResidentialTenancyAct.Chat.Messages
  alias ResidentialTenancyAct.Chat.TokenHistory
  alias ResidentialTenancyAct.LLM
  alias ResidentialTenancyAct.LLM.Prompts
  alias ResidentialTenancyAct.Acts.RTASections

  @impl true
  def mount(%{"conversation_id" => conversation_id}, _session, socket) do
    current_user = socket.assigns.current_user
    # Load conversation by ID
    {:ok, %{conversation: conversation, messages: messages}} =
      load_conversation(conversation_id, current_user)

    socket =
      assign(socket,
        messages: messages,
        current_message: "",
        loading: false,
        selected_state: "NSW",
        sidebar_open: false,
        conversation_id: conversation_id,
        conversation: conversation
      )


    {:ok, socket}
  end

  @impl true
  def mount(_params, _session, socket) do
    # Default mount for new conversations
    socket =
      assign(socket,
        messages: [],
        current_message: "",
        loading: false,
        selected_state: "NSW",
        sidebar_open: false,
        conversation_id: nil,
        conversation: nil
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"conversation_id" => _conversation_id}, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_params(%{}, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(:create_conversation, socket) do
    current_user = socket.assigns.current_user

    conversation =
      Conversations
      |> Ash.Changeset.for_create(:create, %{user_id: current_user.id})
      |> Ash.create!(actor: current_user)

    socket =
      socket
      |> assign(conversation: conversation)
      |> assign(conversation_id: conversation.id)
      |> push_patch(to: ~p"/chat/#{conversation.id}", replace: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("send_message", %{"message" => message}, socket) do
    if String.trim(message) == "" do
      {:noreply, socket}
    else
      current_user = socket.assigns.current_user
      messages = socket.assigns.messages
      conversation = socket.assigns.conversation

      socket =
        if messages == [] && conversation == nil do
          conversation =
            Conversations
            |> Ash.Changeset.for_create(:create, %{}, actor: current_user)
            |> Ash.create!()

          socket
          |> assign(conversation: conversation)
          |> assign(conversation_id: conversation.id)
          |> push_patch(to: ~p"/chat/#{conversation.id}", replace: true)
        else
          socket
        end

      # Create user message
      user_message =
        Messages
        |> Ash.Changeset.for_create(
          :create,
          %{
            content: message,
            role: :user,
            conversation_id: socket.assigns.conversation_id
          },
          actor: current_user
        )
        |> Ash.create!()

      # Update conversation title if this is the first message
      if messages == [] do
        send(
          self(),
          {:generate_title, user_message, socket.assigns.conversation_id, current_user}
        )
      end

      # Show loading state
      socket = assign(socket, loading: true)

      # Send the updated messages to the client immediately
      socket =
        socket
        |> assign(messages: messages ++ [user_message])
        |> assign(current_message: "")

      # Generate assistant response asynchronously
      send(self(), {:generate_response, message, socket.assigns.conversation_id})

      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:generate_title, user_message, conversation_id, current_user}, socket) do
    case generate_title(user_message.content, conversation_id) do
      {:ok, title} ->
        conversation_to_update = Conversations |> Ash.get!(conversation_id, actor: current_user)

        Conversations
        |> Ash.Changeset.for_update(:update, %{title: title}, actor: current_user)
        |> Ash.update!(conversation_to_update)

        {:noreply, socket}

      {:error, _error} ->
        # Fallback to simple title generation
        title = generate_conversation_title(user_message)
        conversation_to_update = Conversations |> Ash.get!(conversation_id, actor: current_user)

        Conversations
        |> Ash.Changeset.for_update(:update, %{title: title}, actor: current_user)
        |> Ash.update!(conversation_to_update)

        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:generate_response, user_message, conversation_id}, socket) do
    current_user = socket.assigns.current_user

    case generate_response(user_message, conversation_id, current_user) do
      {:ok, assistant_message} ->
        socket =
          socket
          |> assign(messages: socket.assigns.messages ++ [assistant_message])
          |> assign(loading: false)

        {:noreply, socket}

      {:error, error} ->
        Logger.error("Failed to generate assistant response", error: error)

        # Create error message
        error_message =
          Messages
          |> Ash.Changeset.for_create(
            :create,
            %{
              content:
                "I'm sorry, I encountered an error while processing your request. Please try again.",
              role: :assistant,
              conversation_id: conversation_id,
              user_id: current_user.id
            },
            actor: current_user
          )
          |> Ash.create!()

        socket =
          socket
          |> assign(messages: socket.assigns.messages ++ [error_message])
          |> assign(loading: false)

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("change_state", %{"state" => state}, socket) do
    {:noreply, assign(socket, selected_state: state)}
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, assign(socket, sidebar_open: !socket.assigns.sidebar_open)}
  end

  @impl true
  def handle_event(
        "keydown",
        %{"key" => "Enter", "shiftKey" => false, "ctrlKey" => false},
        socket
      ) do
    if String.trim(socket.assigns.current_message) != "" do
      {:noreply, push_event(socket, "submit_form", %{})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("keydown", %{"key" => "Enter", "ctrlKey" => true}, socket) do
    if String.trim(socket.assigns.current_message) != "" do
      {:noreply, push_event(socket, "submit_form", %{})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("keydown", _params, socket) do
    {:noreply, socket}
  end

  defp format_timestamp(datetime) do
    Calendar.strftime(datetime, "%I:%M %p")
  end

  defp load_conversation(conversation_id, current_user) do
    conversation =
      Conversations
      |> Ash.get!(conversation_id, actor: current_user)

    messages =
      Messages
      |> Ash.Query.filter(conversation_id: conversation_id)
      |> Ash.Query.sort(created_at: :asc)
      |> Ash.read!(actor: current_user)

    {:ok,
     %{
       conversation: conversation,
       messages: messages
     }}
  end

  defp generate_conversation_title(message) do
    content =
      message.content
      |> String.trim()
      |> String.slice(0, 50)

    if String.length(content) == 50 do
      content <> "..."
    else
      content
    end
  end

  defp generate_response(user_message, conversation_id, current_user) do
    try do
      # Generate embeddings for the user message
      case LLM.generate_embeddings(user_message) do
        {:ok, embeddings} ->
          # Search for relevant RTA sections
          relevant_sections = RTASections.similarity_search(:nsw, embeddings)

          # Build context from relevant sections
          context = build_context_from_sections(relevant_sections)

          # Build the prompt
          prompt = Prompts.build_rta_prompt(user_message, context)

          # Convert conversation history to AWS format
          conversation_messages = get_conversation_messages(conversation_id, current_user)

          aws_messages =
            conversation_messages
            |> Messages.to_aws_messages()
            |> Enum.drop(-1)
            |> Enum.take(-6)
            |> then(&(&1 ++ [%{role: :user, content: prompt}]))

          # Generate response using LLM
          case LLM.generate_text_response(aws_messages) do
            {:ok, %{text: response_text, usage: usage}} ->
              # Create assistant message
              assistant_message =
                Messages
                |> Ash.Changeset.for_create(
                  :create,
                  %{
                    content: response_text,
                    role: :assistant,
                    conversation_id: conversation_id,
                    user_id: current_user.id
                  },
                  actor: current_user
                )
                |> Ash.create!()

              # Update token history
              TokenHistory
              |> Ash.Changeset.for_create(
                :create,
                %{
                  conversation_id: conversation_id,
                  input_tokens: usage["inputTokenCount"],
                  output_tokens: usage["outputTokenCount"]
                },
                actor: current_user
              )
              |> Ash.create!()

              {:ok, assistant_message}

            {:error, error} ->
              Logger.error("LLM response generation failed", error: error)
              {:error, error}
          end

        {:error, error} ->
          Logger.error("Embedding generation failed", error: error)
          {:error, error}
      end
    rescue
      error ->
        Logger.error("Error in generate_response", error: error)
        {:error, error}
    end
  end

  defp build_context_from_sections(sections) do
    sections
    |> Enum.map(fn section ->
      """
      Section #{section.id}: #{section.title}
      URL: #{section.url}

      #{section.text}

      ---
      """
    end)
    |> Enum.join("\n")
  end

  defp get_conversation_messages(conversation_id, current_user) do
    Messages
    |> Ash.Query.filter(conversation_id: conversation_id)
    |> Ash.Query.sort(created_at: :asc)
    |> Ash.read!(actor: current_user)
  end

  defp generate_title(user_message, conversation_id) do
    try do
      prompt = Prompts.build_title_prompt(user_message)

      # Create a simple message for title generation
      title_message = %ResidentialTenancyAct.LLM.AWSNovaRequest.Message{
        role: :user,
        content: [%ResidentialTenancyAct.LLM.AWSNovaRequest.TextContent{text: prompt}]
      }

      case LLM.generate_text_response([title_message]) do
        {:ok, title} ->
          # Clean up the title
          title = title |> String.trim() |> String.replace("\"", "")

          # Update token history
          TokenHistory
          |> Ash.Changeset.for_create(
            :create,
            %{
              conversation_id: conversation_id,
              input_tokens: title.usage["inputTokenCount"],
              output_tokens: title.usage["outputTokenCount"]
            }
          )
          |> Ash.create!()

          {:ok, title}

        {:error, error} ->
          Logger.error("Title generation failed", error: error)
          {:error, error}
      end
    rescue
      error ->
        Logger.error("Error in generate_title", error: error)
        {:error, error}
    end
  end
end
