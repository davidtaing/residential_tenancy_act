defmodule ResidentialTenancyActWeb.ChatLive do
  use ResidentialTenancyActWeb, :live_view

  on_mount {ResidentialTenancyActWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    fake_messages = [
      %{
        id: 1,
        content: "Hi! I'm having issues with my landlord not fixing a leaking tap. What are my rights?",
        role: :user,
        timestamp: DateTime.utc_now() |> DateTime.add(-7200, :second)
      },
      %{
        id: 2,
        content: "Under NSW tenancy law, landlords are required to maintain the property in a reasonable state of repair. A leaking tap would generally be considered an urgent repair that needs to be fixed within a reasonable time.\n\nYou should:\n1. Notify your landlord in writing about the issue\n2. Give them a reasonable time to fix it (usually 14 days for non-urgent repairs)\n3. If they don't respond, you can apply to the NSW Civil and Administrative Tribunal (NCAT)\n\nWould you like me to help you draft a formal request to your landlord?",
        role: :assistant,
        timestamp: DateTime.utc_now() |> DateTime.add(-7100, :second)
      },
      %{
        id: 3,
        content: "Thanks! How much notice do I need to give if I want to move out?",
        role: :user,
        timestamp: DateTime.utc_now() |> DateTime.add(-5400, :second)
      },
      %{
        id: 4,
        content: "In NSW, the notice period depends on your lease type:\n\n• **Fixed-term lease**: You can give notice 14 days before the end of the lease\n• **Periodic lease (month-to-month)**: You need to give 21 days written notice\n• **Breaking a fixed-term lease early**: You may need to pay compensation\n\nMake sure to give notice in writing and keep a copy. Would you like me to explain more about breaking a lease early?",
        role: :assistant,
        timestamp: DateTime.utc_now() |> DateTime.add(-5300, :second)
      },
      %{
        id: 5,
        content: "What about rent increases? How often can my landlord raise the rent?",
        role: :user,
        timestamp: DateTime.utc_now() |> DateTime.add(-3600, :second)
      },
      %{
        id: 6,
        content: "In NSW, rent increases are regulated under the Residential Tenancies Act 2010:\n\n• **Frequency**: Rent can only be increased once every 12 months\n• **Notice**: You must receive at least 60 days written notice before a rent increase\n• **Reasonableness**: The increase must be reasonable compared to market rates\n• **Fixed-term leases**: Rent cannot be increased during a fixed-term lease unless specified in the agreement\n\nIf you believe a rent increase is excessive, you can apply to NCAT within 30 days of receiving the notice. The tribunal will consider factors like:\n- Current market rents for similar properties\n- The condition of the property\n- Any improvements made to the property\n- The landlord's costs and expenses",
        role: :assistant,
        timestamp: DateTime.utc_now() |> DateTime.add(-3500, :second)
      },
      %{
        id: 7,
        content: "Can my landlord enter my property without permission?",
        role: :user,
        timestamp: DateTime.utc_now() |> DateTime.add(-1800, :second)
      },
      %{
        id: 8,
        content: "No, your landlord cannot enter your property without proper notice and permission, except in emergencies. Here are the rules:\n\n**Entry with notice (7-14 days):**\n• Routine inspections (maximum 4 per year)\n• Repairs and maintenance\n• Showing the property to prospective tenants or buyers\n• Valuations\n\n**Entry with 2 days notice:**\n• Emergency repairs\n• Health and safety inspections\n\n**No notice required:**\n• Genuine emergencies (fire, flood, gas leak)\n• When you've abandoned the property\n\nYour landlord must:\n- Give written notice specifying the reason and date/time\n- Only enter during reasonable hours (usually 8am-8pm)\n- Not stay longer than necessary\n- Respect your privacy and quiet enjoyment\n\nIf your landlord enters without proper notice, you can complain to NSW Fair Trading or apply to NCAT.",
        role: :assistant,
        timestamp: DateTime.utc_now() |> DateTime.add(-1700, :second)
      },
      %{
        id: 9,
        content: "What happens if I can't pay my rent on time?",
        role: :user,
        timestamp: DateTime.utc_now() |> DateTime.add(-900, :second)
      },
      %{
        id: 10,
        content: "If you're having trouble paying rent, it's important to act quickly:\n\n**Immediate steps:**\n1. Contact your landlord or agent as soon as possible\n2. Explain your situation and when you expect to pay\n3. Ask about payment plans or extensions\n4. Keep records of all communications\n\n**Your rights:**\n• You cannot be evicted for being 1-2 weeks late\n• Your landlord must give you a termination notice\n• You have time to catch up on payments\n• You can apply to NCAT for more time if needed\n\n**Getting help:**\n• Contact NSW Fair Trading for advice\n• Apply for rental assistance through Centrelink\n• Contact financial counseling services\n• Check if you're eligible for emergency housing assistance\n\n**Avoiding eviction:**\n• Pay what you can, even if it's partial payment\n• Keep your landlord informed of your situation\n• Consider a payment plan\n• Seek help from support services early",
        role: :assistant,
        timestamp: DateTime.utc_now() |> DateTime.add(-800, :second)
      },
      %{
        id: 11,
        content: "Thanks for all the help! This has been really useful.",
        role: :user,
        timestamp: DateTime.utc_now() |> DateTime.add(-300, :second)
      },
      %{
        id: 12,
        content: "You're very welcome! I'm glad I could help you understand your tenancy rights. Remember, if you have any other questions about your tenancy or need help with specific situations, feel free to ask. It's always good to know your rights and obligations as a tenant.\n\nIf you need to take any formal action or have complex legal questions, I'd recommend:\n• Contacting NSW Fair Trading\n• Speaking with a tenant advocacy service\n• Getting legal advice for complex matters\n\nGood luck with your tenancy!",
        role: :assistant,
        timestamp: DateTime.utc_now() |> DateTime.add(-200, :second)
      }
    ]

    socket = assign(socket,
      messages: fake_messages,
      current_message: "",
      loading: false,
      selected_state: "NSW"
    )

    IO.inspect(socket.assigns.messages, label: "Messages in mount")
    {:ok, socket}
  end

  @impl true
  @spec handle_event(<<_::56, _::_*8>>, any(), any()) :: {:noreply, any()}
  def handle_event("send_message", %{"message" => message}, socket) do
    if String.trim(message) != "" do
      # Add user message to the chat
      user_message = %{
        id: System.unique_integer([:positive]),
        content: message,
        role: :user,
        timestamp: DateTime.utc_now()
      }

      # Add bot response placeholder (this will be replaced with actual logic later)
      bot_message = %{
        id: System.unique_integer([:positive]),
        content: "This is a placeholder response. The business logic will be wired up later!",
        role: :assistant,
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
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, socket}
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
      role: :user,
      timestamp: DateTime.utc_now()
    }

    # Add bot response placeholder
    bot_message = %{
      id: System.unique_integer([:positive]),
      content: "This is a placeholder response. The business logic will be wired up later!",
      role: :assistant,
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
