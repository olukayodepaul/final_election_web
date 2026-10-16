defmodule WebApiElection.Reporting.PartyAgentReportQuery do
  alias WebApiElection.Repo
  alias WebApiElection.Reporting.PartyAgentReport

  def insert_report(user_id, uuids, pu_id, ward_id, lg_id, state_id, payload) do
    case Repo.get_by(PartyAgentReport, user_id: user_id, pu_id: pu_id) do
      nil ->
        %PartyAgentReport{}
        |> PartyAgentReport.changeset(%{
          user_id: user_id,
          uuids: uuids,
          pu_id: pu_id,
          ward_id: ward_id,
          lg_id: lg_id,
          state_id: state_id,
          payload: payload
        })
        |> maybe_set_arrival_time(nil, payload)
        |> Repo.insert()

      existing ->
        existing
        |> PartyAgentReport.changeset(%{payload: payload})
        |> maybe_set_arrival_time(existing.payload, payload)
        |> Repo.update()
    end
  end

  defp maybe_set_arrival_time(changeset, stored_payload, new_payload) do
    already_at_unit? = stored_payload && stored_payload["isAtAssignedUnit"] == true

    if !already_at_unit? && new_payload["isAtAssignedUnit"] == true do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      Ecto.Changeset.put_change(changeset, :arrival_time, now)
    else
      changeset
    end
  end
end
