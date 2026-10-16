defmodule WebApiElection.ExternalSocket.Supervisor do
  use DynamicSupervisor
  require Logger

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_user_socket(user_id, token, url) do
    stop_user_socket(user_id)

    spec = %{
      id: WebApiElection.ExternalSocket.Connection,
      start:
        {WebApiElection.ExternalSocket.Connection, :start_link,
         [[user_id: user_id, token: token, url: url]]},
      restart: :transient,
      shutdown: 35_000
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop_user_socket(user_id) do
    case Registry.lookup(WebApiElection.UserSocketRegistry, user_id) do
      [{pid, _value}] ->
        Logger.info("Stopping existing socket for user #{user_id}")
        DynamicSupervisor.terminate_child(__MODULE__, pid)

      [] ->
        :ok
    end
  end
end
