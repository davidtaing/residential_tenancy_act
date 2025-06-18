defmodule ResidentialTenancyAct.Accounts do
  use Ash.Domain, otp_app: :residential_tenancy_act, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource ResidentialTenancyAct.Accounts.Token
    resource ResidentialTenancyAct.Accounts.User
  end
end
