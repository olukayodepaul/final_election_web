defmodule WebApiElection.LoginMonitorQuery do
  import Ecto.Query
  alias WebApiElection.Repo
  alias WebApiElection.Accounts.User

  def get_console_user(username, role_id) do
    from(u in User,
      where: u.username == ^username and u.role_id == ^role_id and u.is_active == true,
      select: %{
        id:        u.id,
        full_name: u.full_name,
        password:  u.password,
        pin:       u.pin
      }
    )
    |> Repo.one()
  end
end
