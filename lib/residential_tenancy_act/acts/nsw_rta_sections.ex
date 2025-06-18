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

  attributes do
    attribute :section_id, :string do
      allow_nil? false
      primary_key? true
    end

    attribute :section_title, :string do
      allow_nil? false
    end

    attribute :part_id, :string do
      allow_nil? false
    end

    attribute :division_id, :string do
      allow_nil? false
    end

    attribute :text, :string do
      allow_nil? false
    end

    attribute :embeddings, :vector do
      allow_nil? false
    end

    attribute :url, :string do
      allow_nil? false
    end
  end
end
