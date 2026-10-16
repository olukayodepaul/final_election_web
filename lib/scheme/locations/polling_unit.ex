# lib/web_api_election/locations/polling_unit.ex
defmodule WebApiElection.Locations.PollingUnit do
  use Ecto.Schema

  schema "polling_units" do
    field :name,              :string
    field :code,              :string
    field :address,           :string
    field :latitude,          :decimal
    field :longitude,         :decimal
    field :registered_voters, :integer
    field :pvc_collected,     :integer
    field :is_active,         :boolean
    field :ward_id,           :integer
    timestamps(type: :utc_datetime)
  end
end
