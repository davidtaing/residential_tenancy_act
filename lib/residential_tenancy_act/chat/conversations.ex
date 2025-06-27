defmodule ResidentialTenancyAct.Chat.Conversations do
  use Ash.Resource,
    domain: ResidentialTenancyAct.Chat,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  import Ecto.Query

  postgres do
    table "conversations"
    repo ResidentialTenancyAct.Repo
  end

  actions do
    defaults [:read]

    create :create do
      change relate_actor(:user, field: :id)
    end

    update :update do
      accept [:title]
    end
  end

  policies do
    policy action_type(:read) do
      description "Users can only read their own conversations"
      authorize_if relates_to_actor_via(:user)
    end

    policy action_type(:create) do
      description "Any one can create a conversation"
      authorize_if always()
    end

    policy action_type(:update) do
      description "Users can only update their own conversations"
      authorize_if relates_to_actor_via(:user)
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :user_id, :uuid do
      allow_nil? false
    end

    attribute :title, :string do
      allow_nil? true
    end

    create_timestamp :created_at

    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, ResidentialTenancyAct.Accounts.User do
      source_attribute :user_id
    end
  end

  def touch(conversation_id) do
    query = from c in __MODULE__,
      where: c.id == ^conversation_id,
      update: [set: [updated_at: fragment("CURRENT_TIMESTAMP")]]

    result = ResidentialTenancyAct.Repo.update_all(query, [])

    case result do
      {1, nil} ->
        :ok

      {0, _} ->
        :error
    end
  end
end
