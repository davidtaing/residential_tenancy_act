defmodule ResidentialTenancyAct.Secrets do
  use AshAuthentication.Secret

  def secret_for(
        [:authentication, :tokens, :signing_secret],
        ResidentialTenancyAct.Accounts.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:residential_tenancy_act, :token_signing_secret)
  end
end
