defmodule WebApiElection.Assignments.FieldOfficerAssignment do
  use Ecto.Schema

  schema "field_officer_assignments" do
    field :field_officer_id,    :integer
    field :state_id,            :integer
    field :local_government_id, :integer
    field :ward_id,             :integer
    field :polling_unit_id,     :integer
    field :assigned_at,         :utc_datetime
    field :assigned_until,      :utc_datetime
  end
end
