defmodule ResidentialTenancyAct.ChatStateServer do
  use GenServer
  alias ResidentialTenancyAct.ChatState

  # -- Public API --

  @spec start_link(pid()) :: GenServer.on_start()
  def start_link(client_pid) do
    GenServer.start_link(__MODULE__, client_pid)
  end

  @doc """
  Change to :searching state with the given prompt.
  """
  @spec change_to_searching(pid(), String.t()) :: :ok
  def change_to_searching(pid, prompt) do
    GenServer.cast(pid, {:change_state, :searching, prompt})
  end

  @doc """
  Change to :generating state with given context.
  """
  @spec change_to_generating(pid(), String.t()) :: :ok
  def change_to_generating(pid, context) do
    GenServer.cast(pid, {:change_state, :generating, context})
  end

  @doc """
  Change to :responding state with generated response.
  """
  @spec change_to_responding(pid(), String.t()) :: :ok
  def change_to_responding(pid, response) do
    GenServer.cast(pid, {:change_state, :responding, response})
  end

  @doc """
  Retrieve the full state struct.
  """
  @spec get_state(pid()) :: ChatState.t()
  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  # -- Callbacks --

  @impl true
  def init(client_pid) do
    {:ok, %ChatState{client: client_pid, state: :idle}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:change_state, :idle}, %ChatState{client: client} = _s) do
    {:noreply, %ChatState{client: client, state: :idle}}
  end

  @impl true
  def handle_cast({:change_state, :searching, prompt}, %ChatState{state: old} = s) do
    if old != :searching do
      send(self(), {:state_transition, :searching})
      {:noreply, %ChatState{s | state: :searching, prompt: prompt}}
    else
      {:noreply, s}
    end
  end

  def handle_cast({:change_state, :generating, context}, %ChatState{state: old} = s) do
    if old != :generating do
      send(self(), {:state_transition, :generating})
      {:noreply, %ChatState{s | state: :generating, context: context}}
    else
      {:noreply, s}
    end
  end

  def handle_cast({:change_state, :responding, response}, %ChatState{state: old} = s) do
    if old != :responding do
      send(self(), {:state_transition, :responding})
      {:noreply, %ChatState{s | state: :responding, response: response}}
    else
      {:noreply, s}
    end
  end

  @impl true
  def handle_info({:state_transition, new_state}, %ChatState{client: client} = state) do
    send(client, {:chat_state_changed, new_state, state})
    {:noreply, state}
  end
end
