defmodule WebApiElection.Assignments.SupervisorWardAssignment do
  use Ecto.Schema

  schema "supervisor_ward_assignments" do
    field :supervisor_id, :integer
    field :ward_id,       :integer
    field :assigned_at,   :utc_datetime
    field :revoked_at,    :utc_datetime
  end
end
