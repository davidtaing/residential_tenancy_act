defmodule ResidentialTenancyAct.Chat.PromptHistory do
  use Ash.Resource,
    domain: ResidentialTenancyAct.Chat,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "prompt_history"
    repo ResidentialTenancyAct.Repo
  end

  actions do
    defaults [:read]

    create :create do
      accept [:message_id, :content]

      change relate_actor(:user, field: :id)
    end
  end

  policies do
    policy action_type(:read) do
      description "Users can only read their own prompt history"
      authorize_if relates_to_actor_via(:user)
    end

    policy action_type(:create) do
      description "Any one can create a prompt history"
      authorize_if always()
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :message_id, :uuid do
      allow_nil? false
    end

    attribute :user_id, :uuid do
      allow_nil? false
    end

    attribute :content, :string do
      allow_nil? false
    end

    create_timestamp :created_at
  end

  relationships do
    belongs_to :user, ResidentialTenancyAct.Accounts.User do
      source_attribute :user_id
    end

    belongs_to :message, ResidentialTenancyAct.Chat.Messages do
      source_attribute :message_id
    end
  end
end
