# lib/web_api_election/reporting/field_officer_current_state.ex
defmodule WebApiElection.Reporting.FieldOfficerCurrentState do
  use Ecto.Schema

  schema "field_officer_current_state" do
    field :user_id,          :integer
    field :state_id,         :integer
    field :lga_id,           :integer
    field :ward_id,          :integer
    field :polling_unit_id,  :integer
    field :last_report_id,   :integer
    field :report_count,     :integer
    field :first_report_at,  :utc_datetime
    field :last_updated_at,  :utc_datetime
    field :acknowledged_at,  :utc_datetime
  end
end
