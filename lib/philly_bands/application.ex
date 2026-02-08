defmodule PhillyBands.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PhillyBandsWeb.Telemetry,
      PhillyBands.Repo,
      {DNSCluster, query: Application.get_env(:philly_bands, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PhillyBands.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: PhillyBands.Finch},
      {Oban, Application.fetch_env!(:philly_bands, Oban)},
      # Start a worker by calling: PhillyBands.Worker.start_link(arg)
      # {PhillyBands.Worker, arg},
      # Start to serve requests, typically the last entry
      PhillyBandsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PhillyBands.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PhillyBandsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
