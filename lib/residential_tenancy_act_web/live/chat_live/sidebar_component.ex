defmodule ResidentialTenancyActWeb.ChatLive.SidebarComponent do
  use ResidentialTenancyActWeb, :live_component

  @impl true
  def render(assigns) do
    sidebar_class = if assigns.sidebar_open, do: "w-80", else: "w-0 overflow-hidden"

    ~H"""
    <div class={"#{sidebar_class} bg-emerald-950 text-white flex flex-col transition-all duration-300"} id="sidebar">
      <!-- Sidebar Header -->
      <div class="p-4 border-b border-emerald-800">
        <div class="flex items-center justify-between">
          <h2 class="text-lg font-medium">Conversations</h2>
          <button
            class="p-2 hover:bg-emerald-800 rounded-md transition-colors"
            phx-click="toggle_sidebar"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>
      </div>

      <!-- Conversation List -->
      <div class="flex-1 overflow-y-auto p-4 space-y-2">
        <div class="space-y-2">
          <a href="/chat/1" class={"block p-3 rounded-lg transition-colors #{if @conversation_id == "1", do: "bg-emerald-800", else: "hover:bg-emerald-800"}"}>
            <div class="text-sm font-medium">Tenancy Rights Discussion</div>
            <div class="text-xs text-emerald-300 mt-1">Today, 2:30 PM</div>
          </a>
          <a href="/chat/2" class={"block p-3 rounded-lg transition-colors #{if @conversation_id == "2", do: "bg-emerald-800", else: "hover:bg-emerald-800"}"}>
            <div class="text-sm font-medium">Rent Increase Questions</div>
            <div class="text-xs text-emerald-300 mt-1">Yesterday, 4:15 PM</div>
          </a>
          <a href="/chat/3" class={"block p-3 rounded-lg transition-colors #{if @conversation_id == "3", do: "bg-emerald-800", else: "hover:bg-emerald-800"}"}>
            <div class="text-sm font-medium">Repair Issues</div>
            <div class="text-xs text-emerald-300 mt-1">2 days ago</div>
          </a>
          <a href="/chat/4" class={"block p-3 rounded-lg transition-colors #{if @conversation_id == "4", do: "bg-emerald-800", else: "hover:bg-emerald-800"}"}>
            <div class="text-sm font-medium">Lease Termination</div>
            <div class="text-xs text-emerald-300 mt-1">1 week ago</div>
          </a>
          <a href="/chat/5" class={"block p-3 rounded-lg transition-colors #{if @conversation_id == "5", do: "bg-emerald-800", else: "hover:bg-emerald-800"}"}>
            <div class="text-sm font-medium">Bond Refund Process</div>
            <div class="text-xs text-emerald-300 mt-1">2 weeks ago</div>
          </a>
        </div>
      </div>

      <!-- Sidebar Footer -->
      <div class="p-4 border-t border-emerald-800">
        <a href="/chat" class="block w-full p-3 bg-emerald-700 hover:bg-emerald-600 rounded-lg transition-colors text-sm font-medium text-center">
          New Conversation
        </a>
      </div>
    </div>
    """
  end
end
