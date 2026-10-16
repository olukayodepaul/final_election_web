defmodule WebApiElection.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contacts" do
    field :name,  :string
    field :email, :string
    timestamps()
  end

  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:name, :email])        # allow these fields
    |> validate_required([:name, :email])  # both must exist
    |> validate_format(:email, ~r/@/)      # must look like an email
  end
end
