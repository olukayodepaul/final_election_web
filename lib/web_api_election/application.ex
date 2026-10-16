defmodule WebApiElection.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WebApiElectionWeb.Telemetry,
      WebApiElection.Repo,
      {DNSCluster, query: Application.get_env(:web_api_election, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: WebApiElection.PubSub},

      {Registry, keys: :unique, name: WebApiElection.UserSocketRegistry},
      {Registry, keys: :unique, name: WebApiElection.UserLiveViewRegistry},
      WebApiElection.ExternalSocket.Supervisor,

      WebApiElectionWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: WebApiElection.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    WebApiElectionWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
