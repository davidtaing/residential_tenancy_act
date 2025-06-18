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
    defaults [:create, :read]

    default_accept [:id, :title, :part_id, :division_id, :url]

    update :update do
      accept [:id, :title, :part_id, :division_id, :url, :text]
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
    end

    attribute :embeddings, :vector do
    end

    attribute :url, :string do
      allow_nil? false
    end
  end
end
