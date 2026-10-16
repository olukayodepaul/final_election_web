defmodule WebApiElection.Reporting.PollingUnitReportQuery do
  alias WebApiElection.Repo
  alias WebApiElection.Reporting.PollingUnitReport

  def insert_report(user_id, uuids, pu_id, ward_id, lg_id, state_id, payload) do
    case Repo.get_by(PollingUnitReport, user_id: user_id, pu_id: pu_id) do
      nil ->
        %PollingUnitReport{}
        |> PollingUnitReport.changeset(%{
          user_id: user_id,
          uuids: uuids,
          pu_id: pu_id,
          ward_id: ward_id,
          lg_id: lg_id,
          state_id: state_id,
          payload: payload
        })
        |> Repo.insert()

      existing ->
        existing
        |> PollingUnitReport.changeset(%{payload: payload})
        |> Repo.update()
    end
  end
end
