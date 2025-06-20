defmodule ResidentialTenancyAct.Acts.NSWRTADivisions do
  use Ash.Resource,
    domain: ResidentialTenancyAct.Acts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.Extension]

  postgres do
    schema "rtas"
    table "nsw_rta_divisions"
    repo ResidentialTenancyAct.Repo
  end

  actions do
    defaults [:create, :read]

    default_accept [:id, :title, :part_id, :division_id]
  end

  attributes do
    attribute :id, :string do
      allow_nil? false
      primary_key? true
    end

    attribute :division_id, :string do
      allow_nil? true
    end

    attribute :title, :string do
      allow_nil? false
    end

    attribute :part_id, :string do
      allow_nil? false
    end
  end

  relationships do
    belongs_to :part, ResidentialTenancyAct.Acts.NSWRTAParts do
      source_attribute :part_id
    end
  end
end
