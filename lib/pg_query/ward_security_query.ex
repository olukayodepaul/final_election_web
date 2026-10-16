defmodule WebApiElection.Reporting.WardSecurityReportQuery do
  alias WebApiElection.Repo
  alias WebApiElection.Reporting.WardSecurityReport

  def insert_report(user_id, uuids, pu_id, ward_id, lg_id, state_id, payload) do
    case Repo.get_by(WardSecurityReport, user_id: user_id, ward_id: ward_id) do
      nil ->
        %WardSecurityReport{}
        |> WardSecurityReport.changeset(%{
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
        |> WardSecurityReport.changeset(%{payload: payload})
        |> Repo.update()
    end
  end
end
