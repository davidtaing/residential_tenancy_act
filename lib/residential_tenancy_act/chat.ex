defmodule ResidentialTenancyAct.Chat do
  use Ash.Domain, otp_app: :residential_tenancy_act

  resources do
    resource ResidentialTenancyAct.Chat.Messages
    resource ResidentialTenancyAct.Chat.Conversations
    resource ResidentialTenancyAct.Chat.TokenHistory
  end
end
