defmodule ResidentialTenancyActWeb.WelcomeMessageComponent do
  use ResidentialTenancyActWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="flex justify-center items-center h-full">
      <div class="text-center max-w-lg">
        <h2 class="mt-10 text-3xl font-light mb-4 text-emerald-950">Welcome to TenancyBot</h2>
        <p class="text-lg mb-8 leading-relaxed text-emerald-800">
          I'm here to help you understand tenancy laws and regulations.
          Ask me questions about your rights and obligations.
        </p>
        <div class="space-y-3 mb-8">
          <div class="inline-block px-4 py-2 rounded-full text-sm bg-emerald-300 text-emerald-900">
            "What are my rights as a tenant?"
          </div>
          <div class="inline-block px-4 py-2 rounded-full text-sm bg-emerald-300 text-emerald-900">
            "How much notice do I need to give?"
          </div>
          <div class="inline-block px-4 py-2 rounded-full text-sm bg-emerald-300 text-emerald-900">
            "What can I do about repairs?"
          </div>
        </div>
        <div class="p-4 rounded-lg bg-emerald-200 border border-emerald-300">
          <p class="text-sm text-emerald-800">
            <strong>Note:</strong> Currently supporting NSW only. Other states coming soon!
          </p>
        </div>
      </div>
    </div>
    """
  end
end
