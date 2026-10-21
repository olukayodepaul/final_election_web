defmodule WebApiElection.Assignments.SupervisorWardAssignment do
  use Ecto.Schema
  import Ecto.Query
  alias WebApiElection.Repo

  schema "supervisor_ward_assignments" do
    field :supervisor_id, :integer
    field :ward_id,       :integer
    field :lg_id,         :integer
    field :state_id,      :integer
    field :assigned_at,   :utc_datetime
    field :revoked_at,    :utc_datetime
  end

  @doc """
  Active ward assignments for one supervisor, as plain maps.
  A row counts when it has not been revoked (or the revocation is still in the future).
  """
  def active_for_supervisor(supervisor_id) do
    now = DateTime.truncate(DateTime.utc_now(), :second)

    from(a in __MODULE__,
      where: a.supervisor_id == ^supervisor_id,
      where: is_nil(a.revoked_at) or a.revoked_at > ^now,
      select: %{ward_id: a.ward_id, lg_id: a.lg_id, state_id: a.state_id}
    )
    |> Repo.all()
  end
end
