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
      primary_key? true
    end
  end
end
