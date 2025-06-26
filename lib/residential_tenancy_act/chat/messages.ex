defmodule ResidentialTenancyAct.Chat.Messages do
  use Ash.Resource,
    domain: ResidentialTenancyAct.Chat,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "messages"
    repo ResidentialTenancyAct.Repo
  end

  actions do
    defaults [:read]

    create :create do
      accept [:user_id, :role, :content, :conversation_id]

      change relate_actor(:user, field: :id)
    end
  end

  policies do
    policy action_type(:read) do
      description "Users can only read their own messages"
      authorize_if relates_to_actor_via(:user)
    end

    policy action_type(:create) do
      description "Any one can create a messages"
      authorize_if always()
    end

    policy action_type(:update) do
      description "Users can only update their own messages"
      authorize_if relates_to_actor_via(:user)
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :user_id, :uuid do
      allow_nil? false
    end

    attribute :role, :atom do
      allow_nil? false
      constraints one_of: [:user, :assistant]
    end

    attribute :content, :string do
      allow_nil? false
    end

    attribute :conversation_id, :uuid do
      allow_nil? false
    end

    create_timestamp :created_at
  end

  relationships do
    belongs_to :user, ResidentialTenancyAct.Accounts.User do
      source_attribute :user_id
    end

    belongs_to :conversation, ResidentialTenancyAct.Chat.Conversations do
      source_attribute :conversation_id
    end
  end

  @spec to_aws_messages([%{role: atom(), content: String.t()}]) :: [
          ResidentialTenancyAct.LLM.AWSNovaRequest.Message.t()
        ]
  def to_aws_messages(messages) do
    messages
    |> Enum.map(fn message ->
      %ResidentialTenancyAct.LLM.AWSNovaRequest.Message{
        role: message.role,
        content: [%ResidentialTenancyAct.LLM.AWSNovaRequest.TextContent{text: message.content}]
      }
    end)
  end
end
