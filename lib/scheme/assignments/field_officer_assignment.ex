defmodule WebApiElection.Assignments.FieldOfficerAssignment do
  use Ecto.Schema
  import Ecto.Query
  alias WebApiElection.Repo
  alias WebApiElection.Accounts.User
  alias WebApiElection.Locations.{PollingUnit, Ward, LocalGovernment, State}

  schema "field_officer_assignments" do
    field :field_officer_id,    :integer
    field :state_id,            :integer
    field :local_government_id, :integer
    field :ward_id,             :integer
    field :polling_unit_id,     :integer
    field :assigned_at,         :utc_datetime
    field :assigned_until,      :utc_datetime
  end

  def active_for_wards([]), do: []

  def active_for_wards(ward_assignments) do
    ward_ids = Enum.map(ward_assignments, & &1.ward_id)
    allowed = MapSet.new(ward_assignments, &{&1.ward_id, &1.lg_id, &1.state_id})
    now = DateTime.truncate(DateTime.utc_now(), :second)

    from(f in __MODULE__,
      join: u in User, on: u.id == f.field_officer_id,
      join: p in PollingUnit, on: p.id == f.polling_unit_id,
      join: w in Ward, on: w.id == f.ward_id,
      join: l in LocalGovernment, on: l.id == f.local_government_id,
      join: s in State, on: s.id == f.state_id,
      where: f.ward_id in ^ward_ids,
      where: is_nil(f.assigned_until) or f.assigned_until > ^now,
      select: %{
        user_id: u.id,
        user_name: u.full_name,
        polling_unit_id: p.id,
        pu_name: p.name,
        pu_code: p.code,
        registered_voters: p.registered_voters,
        ward_id: f.ward_id,
        ward_name: w.name,
        ward_code: w.code,
        lg_id: f.local_government_id,
        lg_name: l.name,
        lg_code: l.code,
        state_id: f.state_id,
        state_name: s.name,
        state_code: s.code
      }
    )
    |> Repo.all()
    |> Enum.filter(&MapSet.member?(allowed, {&1.ward_id, &1.lg_id, &1.state_id}))
  end
end
