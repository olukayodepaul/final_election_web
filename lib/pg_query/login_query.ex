defmodule WebApiElection.LoginQuery do
  import Ecto.Query
  alias WebApiElection.Repo
  alias WebApiElection.Accounts.{User, UserRole}
  alias WebApiElection.Assignments.{FieldOfficerAssignment, SupervisorWardAssignment}
  alias WebApiElection.Elections.{ElectionSchedule, ElectionType, Election}
  alias WebApiElection.Locations.{PollingUnit, Ward, LocalGovernment, State}

  def get_field_officer(username) do

    total_pu_subquery =
      from(ipu in PollingUnit,
        where: ipu.ward_id == parent_as(:pu).ward_id,
        select: count(ipu.id)
      )

    elections_subquery =
      from(e in Election,
        where: e.types == 1 and e.is_active == true,
        select: fragment("json_agg(?)", e)
      )

    from(un in User,
      join: ur   in UserRole,                 on: un.role_id == ur.id,
      join: foa  in FieldOfficerAssignment,   on: un.id == foa.field_officer_id,
      join: swa  in SupervisorWardAssignment, on: foa.ward_id == swa.ward_id,
      join: es   in ElectionSchedule,         on: es.is_active == true,
      join: elt  in ElectionType,             on: true,
      join: els1 in Election,                 on: els1.map_id == 1 and elt.election_id_1 == els1.id,
      join: els2 in Election,                 on: els2.map_id == 2 and elt.election_id_2 == els2.id,
      join: pu   in PollingUnit,              as: :pu, on: foa.polling_unit_id == pu.id,
      join: wds  in Ward,                     on: foa.ward_id == wds.id,
      join: lg   in LocalGovernment,          on: foa.local_government_id == lg.id,
      join: sts  in State,                    on: foa.state_id == sts.id,

      where: un.username == ^username,
      where: is_nil(foa.assigned_until),

      select: %{
        id:                 un.id,
        pin:                un.pin,
        password:           un.password,
        roles:              ur.name,
        role_id:            ur.id,
        username:           un.username,
        full_name:          un.full_name,
        field_officer_id:   un.id,
        supervisor_id:      swa.supervisor_id,
        start_date:         es.start_date,
        end_date:           es.end_date,
        election_date:      es.election_date,
        lead_ele_type:      els1.map_id,
        trail_ele_type:     els2.map_id,
        lead_ele_name:      els1.name,
        trail_ele_name:     els2.name,
        lat:                pu.latitude,
        long:               pu.longitude,
        registered_voters:  pu.registered_voters,
        pvc_collected:      pu.pvc_collected,
        polling_unit_id:    pu.id,
        polling_unit_name:  pu.name,
        polling_unit_code:  pu.code,
        ward_code:          wds.code,
        ward_name:          wds.name,
        ward_id:            wds.id,
        lg_code:            lg.code,
        lg_name:            lg.name,
        lg_id:              lg.id,
        state_code:         sts.code,
        state_name:         sts.name,
        state_id:           sts.id,
        total_pu_in_ward:   subquery(total_pu_subquery),
        elections:          subquery(elections_subquery)
      }
    )
    |> Repo.one()
  end

end
