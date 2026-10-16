defmodule WebApiElection.Reporting.PollingUnitSecurityReportQuery do
  alias WebApiElection.Repo
  alias WebApiElection.Reporting.PollingSecuriyReport

  def insert_report(user_id, uuids, pu_id, ward_id, lg_id, state_id, payload) do
    case Repo.get_by(PollingSecuriyReport, user_id: user_id, pu_id: pu_id) do
      nil ->
        %PollingSecuriyReport{}
        |> PollingSecuriyReport.changeset(%{
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
        |> PollingSecuriyReport.changeset(%{payload: payload})
        |> Repo.update()
    end
  end
end
