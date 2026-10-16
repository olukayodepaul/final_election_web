# lib/web_api_election/locations/local_government.ex
defmodule WebApiElection.Locations.LocalGovernment do
  use Ecto.Schema

  schema "local_governments" do
    field :name,     :string
    field :code,     :string
    field :state_id, :integer
    timestamps(type: :utc_datetime)
  end
end
