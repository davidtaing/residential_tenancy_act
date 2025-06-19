defmodule ResidentialTenancyAct.Acts.NSWRTASections do
  use Ash.Resource,
    domain: ResidentialTenancyAct.Acts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.Extension]

  postgres do
    schema "rtas"
    table "nsw_rta_sections"
    repo ResidentialTenancyAct.Repo
  end

  actions do
    defaults [:create]

    default_accept [:id, :title, :part_id, :division_id, :url]

    read :read do
      primary? true

      pagination do
        required? false
        offset? true
        countable true
      end
    end

    update :update do
      accept [
        :id,
        :title,
        :part_id,
        :division_id,
        :url,
        :text,
        :hash,
        :token_count,
        :embeddings_stale,
        :embeddings
      ]
    end
  end

  attributes do
    attribute :id, :string do
      allow_nil? false
      primary_key? true
    end

    attribute :title, :string do
      allow_nil? false
    end

    attribute :part_id, :string do
      allow_nil? false
    end

    attribute :division_id, :string do
      allow_nil? false
    end

    attribute :text, :string do
      allow_nil? true
    end

    attribute :embeddings, :vector do
      allow_nil? true
    end

    attribute :url, :string do
      allow_nil? false
    end

    attribute :token_count, :integer do
      allow_nil? true
    end

    attribute :hash, :string do
      allow_nil? true
    end

    attribute :embeddings_stale, :boolean do
      allow_nil? false
      default false
    end
  end

  def table_name(), do: "nsw_rta_sections"
end
