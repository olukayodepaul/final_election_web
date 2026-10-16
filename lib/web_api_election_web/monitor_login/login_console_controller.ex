defmodule WebApiElectionWeb.ApiLoginMonitorController do
  use WebApiElectionWeb, :controller
  alias WebApiElection.LoginMonitorQuery

  def api_login_monitor(conn, %{"username" => username, "password" => password, "role_id" => role_id}) do
    case LoginMonitorQuery.get_console_user(username, role_id) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{status: %{code: 401, message: :unauthorized}})

      result ->
        if Bcrypt.verify_pass(password, result.password) do
          {:ok, tokens} = JWT.Issuer.generate_tokens(%{
            device_id: "bim#{result.id}",
            eid:       "bim#{result.id}@bimip.com",
            user_id:   "#{result.id}"
          })

          # url = "wss://127.0.0.1:4000"
          # WebApiElection.ExternalSocket.Supervisor.start_user_socket(result.id, tokens.access, url)

          conn
          |> put_status(:ok)
          |> json(%{
            status: %{code: 200, message: :ok},
            data: %{id: result.id, full_name: result.full_name, pin: result.pin, token: tokens}
          })
        else
          conn
          |> put_status(:unauthorized)
          |> json(%{status: %{code: 401, message: "invalid password"}})
        end
    end
  end

  def api_login_monitor(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{status: %{code: 400, message: :bad_request}})
  end
end
