defmodule ResidentialTenancyAct.Chat.TokenHistory do
  use Ash.Resource,
    domain: ResidentialTenancyAct.Chat,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "token_history"
    repo ResidentialTenancyAct.Repo
  end

  actions do
    defaults [:read]

    create :create do
      accept [:conversation_id, :input_tokens, :output_tokens]

      change relate_actor(:user, field: :id)
    end
  end

  policies do
    policy action_type(:read) do
      description "Users can only read their own token history"
      authorize_if relates_to_actor_via(:user)
    end

    policy action_type(:create) do
      description "Any one can create a token history"
      authorize_if always()
    end

    policy action_type(:update) do
      description "Users can only update their own token history"
      authorize_if relates_to_actor_via(:user)
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :user_id, :uuid do
      allow_nil? false
    end

    attribute :conversation_id, :uuid do
      allow_nil? false
    end

    attribute :input_tokens, :integer do
      allow_nil? false
    end

    attribute :output_tokens, :integer do
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
end
