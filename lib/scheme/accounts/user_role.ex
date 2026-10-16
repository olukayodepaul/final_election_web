defmodule WebApiElection.Accounts.UserRole do
  use Ecto.Schema

  schema "user_roles" do
    field :name,        :string
    field :description, :string
    timestamps(type: :utc_datetime)
  end
end
