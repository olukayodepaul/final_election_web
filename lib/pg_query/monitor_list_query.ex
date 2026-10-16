defmodule WebApiElection.SupervisorMonitorQuery do
  import Ecto.Query
  alias WebApiElection.Repo
  alias WebApiElection.Accounts.User
  alias WebApiElection.Assignments.{FieldOfficerAssignment, SupervisorWardAssignment}
  alias WebApiElection.Elections.ElecCurrentState
  alias WebApiElection.Locations.{Ward, LocalGovernment, State, PollingUnit}

  def get_field_officer_states(supervisor_id) do
    from(
      a in SupervisorWardAssignment,
      join: supervisor in User,            on: supervisor.id == a.supervisor_id,
      join: c in FieldOfficerAssignment,   on: c.ward_id == a.ward_id,
      join: fo in User,                    on: fo.id == c.field_officer_id, # Join User table for Field Officer
      join: d in ElecCurrentState,         on: d.user_id == c.field_officer_id,
      join: e in Ward,                     on: e.id == c.ward_id,
      join: f in LocalGovernment,          on: f.id == c.local_government_id,
      join: g in State,                    on: g.id == c.state_id,
      join: h in PollingUnit,              on: h.id == c.polling_unit_id,

      where: supervisor.id == ^supervisor_id,

      select: %{
        supervisor_name:    supervisor.full_name,
        field_officer_name: fo.full_name, # Select Field Officer Name
        pu_code:    h.code,
        pu_name:    h.name,
        rgv:        h.registered_voters,
        pc:         h.pvc_collected,
        ward_code:  e.code,
        ward_name:  e.name,
        lg_code:    f.code,
        lg_name:    f.name,
        state_code: g.code,
        state_name: g.name,
        supervisor_id: a.supervisor_id,
        field_officer_id: c.field_officer_id,
        id:                         d.id,
        user_id:                    d.user_id,
        inec_ar_time:               d.inec_ar_time,
        official_no:                d.official_no,
        security_present:           d.security_present,
        is_bvas_available:          d.is_bvas_available,
        is_bvas_working:            d.is_bvas_working,
        is_voters_verify:           d.is_voters_verify,
        is_voters_verify_with_bvas: d.is_voters_verify_with_bvas,
        is_voters_verify_with_bvas_time: d.is_voters_verify_with_bvas_time,
        has_accr_commence:          d.has_accr_commence,
        has_voting_commence:        d.has_voting_commence,
        is_conclusive_time:         d.is_conclusive_time,
        are_security_present:       d.are_security_present,
        is_agent_at_polling_unit:   d.is_agent_at_polling_unit,
        did_inec_clear_agent:       d.did_inec_clear_agent,
        is_conclusive:              d.is_conclusive,
        has_proceed_to_ward:        d.has_proceed_to_ward,
        arrival_time:               d.arrival_time,
        accr_started_at:            d.accr_started_at,
        voting_started_at:          d.voting_started_at,
        collation_status_time:      d.collation_status_time,
        result_upload_to_irev_time: d.result_upload_to_irev_time,
        is_bvas_working_time: d.is_bvas_working_time,
        is_bvas_available_time: d.is_bvas_available_time,
        did_inec_clear_agent_time: d.did_inec_clear_agent_time,
        security_present_time: d.security_present_time,
        is_pu_officer_at_collation_center:   d.is_pu_officer_at_collation_center,
        is_pu_officer_at_collation_center_ar_time: d.is_pu_officer_at_collation_center_ar_time,
        is_inec_officer_at_collation_center: d.is_inec_officer_at_collation_center,
        is_inec_officer_same_as_pu_officer:  d.is_inec_officer_same_as_pu_officer,
        result_upload_to_irev:               d.result_upload_to_irev
      }
    )
    |> Repo.all()
  end
end
