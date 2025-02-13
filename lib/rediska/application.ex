defmodule Rediska.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RediskaWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:rediska, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Rediska.PubSub},
      {Redix, host: "localhost", name: :redis, port: 6379},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Rediska.Finch},
      # Start a worker by calling: Rediska.Worker.start_link(arg)
      # {Rediska.Worker, arg},
      # Start to serve requests, typically the last entry
      RediskaWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rediska.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RediskaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
