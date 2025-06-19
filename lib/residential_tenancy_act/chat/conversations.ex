defmodule ResidentialTenancyAct.Chat.Conversations do
  use Ash.Resource,
    domain: ResidentialTenancyAct.Chat,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "conversations"
    repo ResidentialTenancyAct.Repo
  end

  actions do
    defaults [:read]

    create :create do
      accept []

      change relate_actor(:user, field: :id)
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :user_id, :uuid do
      allow_nil? false
    end

    create_timestamp :created_at

    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, ResidentialTenancyAct.Accounts.User do
      source_attribute :user_id
    end
  end
end
