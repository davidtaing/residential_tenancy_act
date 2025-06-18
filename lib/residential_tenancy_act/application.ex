defmodule ResidentialTenancyAct.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ResidentialTenancyActWeb.Telemetry,
      ResidentialTenancyAct.Repo,
      {DNSCluster,
       query: Application.get_env(:residential_tenancy_act, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:residential_tenancy_act, Oban)},
      {Phoenix.PubSub, name: ResidentialTenancyAct.PubSub},
      # Start a worker by calling: ResidentialTenancyAct.Worker.start_link(arg)
      # {ResidentialTenancyAct.Worker, arg},
      # Start to serve requests, typically the last entry
      ResidentialTenancyActWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :residential_tenancy_act]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ResidentialTenancyAct.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ResidentialTenancyActWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
