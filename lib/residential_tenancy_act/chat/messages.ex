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
    defaults [:create, :read]

    default_accept [:user_id, :role, :content]
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

  def to_aws_messages(messages) do
    messages
    |> Enum.map(fn message ->
      %{
        "role" => Atom.to_string(message.role),
        "content" => [%{"text" => message.content}]
      }
    end)
  end
end
