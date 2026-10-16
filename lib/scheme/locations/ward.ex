# lib/web_api_election/locations/ward.ex
defmodule WebApiElection.Locations.Ward do
  use Ecto.Schema

  schema "wards" do
    field :name,   :string
    field :code,   :string
    field :lga_id, :integer
    timestamps(type: :utc_datetime)
  end
end
