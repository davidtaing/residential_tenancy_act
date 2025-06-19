defmodule ResidentialTenancyAct.Acts do
  use Ash.Domain, otp_app: :residential_tenancy_act

  resources do
    resource ResidentialTenancyAct.Acts.NSWRTASections
    resource ResidentialTenancyAct.Acts.NSWRTADivisions
    resource ResidentialTenancyAct.Acts.NSWRTAParts
  end
end
