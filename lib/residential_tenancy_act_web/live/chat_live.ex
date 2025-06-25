defmodule ResidentialTenancyActWeb.ChatLive do
  use ResidentialTenancyActWeb, :live_view

  on_mount {ResidentialTenancyActWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       messages: [],
       current_message: "",
       loading: false,
       selected_state: "NSW"
     )}
  end

  @impl true
  def handle_event("send_message", %{"message" => message}, socket) do
    if String.trim(message) != "" do
      # Add user message to the chat
      user_message = %{
        id: System.unique_integer([:positive]),
        content: message,
        sender: :user,
        timestamp: DateTime.utc_now()
      }

      # Add bot response placeholder (this will be replaced with actual logic later)
      bot_message = %{
        id: System.unique_integer([:positive]),
        content: "This is a placeholder response. The business logic will be wired up later!",
        sender: :bot,
        timestamp: DateTime.utc_now()
      }

      {:noreply,
       socket
       |> assign(messages: socket.assigns.messages ++ [user_message, bot_message])
       |> assign(current_message: "")
       |> assign(loading: false)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_message", %{"value" => message}, socket) do
    {:noreply, assign(socket, current_message: message)}
  end

  @impl true
  def handle_event("change_state", %{"state" => state}, socket) do
    {:noreply, assign(socket, selected_state: state)}
  end

  @impl true
  def handle_event(
        "keydown",
        %{"key" => "Enter", "shiftKey" => false, "ctrlKey" => false},
        socket
      ) do
    if String.trim(socket.assigns.current_message) != "" do
      send(self(), {:send_message, socket.assigns.current_message})
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("keydown", %{"key" => "Enter", "ctrlKey" => true}, socket) do
    if String.trim(socket.assigns.current_message) != "" do
      send(self(), {:send_message, socket.assigns.current_message})
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("keydown", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:send_message, message}, socket) do
    # Add user message to the chat
    user_message = %{
      id: System.unique_integer([:positive]),
      content: message,
      sender: :user,
      timestamp: DateTime.utc_now()
    }

    # Add bot response placeholder
    bot_message = %{
      id: System.unique_integer([:positive]),
      content: "This is a placeholder response. The business logic will be wired up later!",
      sender: :bot,
      timestamp: DateTime.utc_now()
    }

    {:noreply,
     socket
     |> assign(messages: socket.assigns.messages ++ [user_message, bot_message])
     |> assign(current_message: "")
     |> assign(loading: false)}
  end

  defp format_timestamp(datetime) do
    Calendar.strftime(datetime, "%I:%M %p")
  end
end
