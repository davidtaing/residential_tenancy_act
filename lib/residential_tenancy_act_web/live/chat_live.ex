defmodule ResidentialTenancyActWeb.ChatLive do
  use ResidentialTenancyActWeb, :live_view

  on_mount {ResidentialTenancyActWeb.LiveUserAuth, :live_user_required}

  require Ash.Query
  require Logger

  import ResidentialTenancyActWeb.MarkdownHelper, only: [render_markdown: 1]

  alias ResidentialTenancyActWeb.ChatLive.SidebarComponent
  alias ResidentialTenancyAct.Chat.Conversations
  alias ResidentialTenancyAct.Chat.Messages
  alias ResidentialTenancyAct.Chatbot
  alias ResidentialTenancyAct.ChatStateServer

  @impl true
  def mount(%{"conversation_id" => conversation_id}, _session, socket) do
    current_user = socket.assigns.current_user

    {:ok, %{conversation: conversation, messages: messages}} =
      load_conversation(conversation_id, current_user)

    {:ok, server_pid} = ChatStateServer.start_link(self())

    socket =
      assign(socket,
        messages: messages,
        current_message: "",
        loading: false,
        selected_state: "NSW",
        sidebar_open: false,
        conversation_id: conversation_id,
        conversation: conversation,
        server_pid: server_pid
      )

    {:ok, socket}
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, server_pid} = ChatStateServer.start_link(self())

    # Default mount for new conversations
    socket =
      assign(socket,
        messages: [],
        current_message: "",
        loading: false,
        selected_state: "NSW",
        sidebar_open: false,
        conversation_id: nil,
        conversation: nil,
        server_pid: server_pid
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
  def handle_info({:generate_response, messages, conversation_id}, socket) do
    Task.start(fn ->
      metadata = %{
        conversation_id: conversation_id,
        user_id: socket.assigns.current_user.id
      }

      Chatbot.generate_response(
        socket.assigns.server_pid,
        messages,
        socket.assigns.current_user,
        metadata
      )
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:chat_state_changed, :searching, _chat_state}, socket) do
    socket =
      socket
      |> assign(loading: true)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:chat_state_changed, :generating, _chat_state}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:chat_state_changed, :responding, chat_state}, socket) do
    message = chat_state.response

    messages = socket.assigns.messages ++ [message]

    socket =
      socket
      |> assign(messages: messages)
      |> assign(loading: false)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:chat_state_changed, :idle, _chat_state}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:chat_state_changed, :error, _chat_state}, socket) do
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

      # # Update conversation title if this is the first message
      # if messages == [] do
      #   send(
      #     self(),
      #     {:generate_title, user_message, socket.assigns.conversation_id, current_user}
      #   )
      # end

      messages = messages ++ [user_message]

      # Send the updated messages to the client immediately
      socket =
        socket
        |> assign(loading: true)
        |> assign(messages: messages)
        |> assign(current_message: "")

      # Generate assistant response asynchronously
      send(
        self(),
        {:generate_response, messages, conversation_id: socket.assigns.conversation_id}
      )

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
  def handle_event("keydown", %{"key" => "Enter", "ctrlKey" => true}, socket) do
    if String.trim(socket.assigns.current_message) != "" do
      {:noreply, push_event(socket, "submit_form", %{})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("keydown", %{"key" => "Enter"}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("keydown", %{"value" => value}, socket) do
    socket =
      socket
      |> assign(current_message: value)

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
end
