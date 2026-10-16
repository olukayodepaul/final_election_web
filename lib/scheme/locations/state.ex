# lib/web_api_election/locations/state.ex
defmodule WebApiElection.Locations.State do
  use Ecto.Schema

  schema "states" do
    field :name, :string
    field :code, :string
    timestamps(type: :utc_datetime)
  end
end
