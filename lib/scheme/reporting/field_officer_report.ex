# lib/web_api_election/reporting/field_officer_report.ex
defmodule WebApiElection.Reporting.FieldOfficerReport do
  use Ecto.Schema

  schema "field_officer_reports" do
    field :user_id,         :integer
    field :state_id,        :integer
    field :lga_id,          :integer
    field :ward_id,         :integer
    field :polling_unit_id, :integer
    field :device_id,       :string
    field :submitted_at,    :utc_datetime
  end
end
