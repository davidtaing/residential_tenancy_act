defmodule ResidentialTenancyAct.Acts.NSWRTAPart do
  use Ash.Resource,
    domain: ResidentialTenancyAct.Acts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.Extension]

  postgres do
    schema "rtas"
    table "nsw_rta_parts"
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
  end
end
