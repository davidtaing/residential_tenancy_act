defmodule ResidentialTenancyActWeb.ChatLive.SidebarComponent do
  use ResidentialTenancyActWeb, :live_component

  require Ash.Query

  alias ResidentialTenancyAct.Chat.Conversations

  @impl true
  def update(assigns, socket) do
    current_user = assigns.current_user
    sidebar_open = assigns.sidebar_open
    conversation_id = assigns.conversation_id

    conversations =
      Conversations
      |> Ash.Query.filter(user_id: current_user.id)
      |> Ash.Query.sort(created_at: :desc)
      |> Ash.read!(actor: current_user)

    socket =
      socket
      |> assign(
        conversations: conversations,
        current_user: current_user,
        sidebar_open: sidebar_open,
        conversation_id: conversation_id
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class={"#{if @sidebar_open, do: "w-80", else: "w-0 overflow-hidden"} bg-emerald-950 text-white flex flex-col transition-all duration-300"}
      id="sidebar"
    >
      <!-- Sidebar Header -->
      <div class="p-4 border-b border-emerald-800">
        <div class="flex items-center justify-between">
          <h2 class="text-lg font-medium">Conversations</h2>
          <button
            class="p-2 hover:bg-emerald-800 rounded-md transition-colors"
            phx-click="toggle_sidebar"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              >
              </path>
            </svg>
          </button>
        </div>
      </div>
      
    <!-- Conversation List -->
      <div class="flex-1 overflow-y-auto p-4 space-y-2">
        <%= if Enum.empty?(@conversations) do %>
          <div class="text-center py-8">
            <div class="text-emerald-300 text-sm">No conversations yet</div>
            <div class="text-emerald-500 text-xs mt-1">Start a new conversation to begin</div>
          </div>
        <% else %>
          <div class="space-y-2">
            <%= for conversation <- @conversations do %>
              <a
                href={~p"/chat/#{conversation.id}"}
                class={"block p-3 rounded-lg transition-colors #{if @conversation_id == conversation.id, do: "bg-emerald-800", else: "hover:bg-emerald-800"}"}
              >
                <div class="text-sm font-medium">
                  {conversation.title || "New Conversation"}
                </div>
                <div class="text-xs text-emerald-300 mt-1">
                  {format_relative_time(conversation.created_at)}
                </div>
              </a>
            <% end %>
          </div>
        <% end %>
      </div>
      
    <!-- Sidebar Footer -->
      <div class="p-4 border-t border-emerald-800">
        <a
          href="/chat"
          class="block w-full p-3 bg-emerald-700 hover:bg-emerald-600 rounded-lg transition-colors text-sm font-medium text-center"
        >
          New Conversation
        </a>
      </div>
    </div>
    """
  end

  defp format_relative_time(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "Just now"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      diff < 604_800 -> "#{div(diff, 86400)}d ago"
      diff < 2_592_000 -> "#{div(diff, 604_800)}w ago"
      true -> Calendar.strftime(datetime, "%b %d, %Y")
    end
  end
end
