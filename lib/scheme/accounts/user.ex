# lib/web_api_election/accounts/user.ex
defmodule WebApiElection.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :full_name,  :string
    field :username,   :string
    field :password,   :string
    field :pin,        :integer
    field :device_id,  :string
    field :is_active,  :boolean
    field :last_login, :utc_datetime
    field :role_id,    :integer
    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:full_name, :username, :password, :pin, :device_id, :is_active, :last_login, :role_id])
    |> validate_required([:full_name, :username, :password])
    |> unique_constraint(:username)
  end
end
