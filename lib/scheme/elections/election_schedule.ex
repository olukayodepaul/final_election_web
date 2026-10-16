defmodule WebApiElection.Elections.ElectionSchedule do
  use Ecto.Schema
  schema "election_schedule" do
    field :election_name, :string
    field :election_date, :date
    field :start_date,    :utc_datetime
    field :end_date,      :utc_datetime
    field :is_active,     :boolean
  end
end
