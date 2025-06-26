defmodule ResidentialTenancyAct.ChatState do
  @moduledoc """
  Struct representing the internal state of a chat session.
  """

  @enforce_keys [:client]

  defstruct client: nil,
            state: :idle,
            prompt: nil,
            context: nil,
            response: nil

  @type state_type :: :idle | :searching | :generating | :responding | :error

  @type t :: %__MODULE__{
          client: pid(),
          state: state_type(),
          prompt: String.t() | nil,
          context: String.t() | nil,
          response: String.t() | nil
        }
end
