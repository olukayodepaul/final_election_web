# lib/web_api_election/reporting/election_result_report_query.ex
defmodule WebApiElection.Reporting.ElectionResultReportQuery do
  import Ecto.Query
  alias WebApiElection.Repo
  alias WebApiElection.Reporting.ElectionResultReport
  alias WebApiElection.Locations.{PollingUnit, Ward, LocalGovernment, State}
  alias WebApiElection.Accounts.User

  def insert_report(user_id, election_id, pu_id, ward_id, lg_id, state_id, payload, upload_url) do
    case Repo.get_by(ElectionResultReport, user_id: user_id, election_id: election_id) do
      nil ->
        %ElectionResultReport{}
        |> ElectionResultReport.changeset(%{
          user_id: user_id,
          election_id: election_id,
          pu_id: pu_id,
          ward_id: ward_id,
          lg_id: lg_id,
          state_id: state_id,
          payload: payload,
          upload_url: upload_url
        })
        |> Repo.insert()

      existing ->
        {:error, :already_exists, existing}
    end
  end

  def fetch_results_for_supervisor(supervisor_id) do
    ward_ids_subquery = ward_ids_query(supervisor_id)

    from(a in ElectionResultReport,
      join: b in PollingUnit, on: a.pu_id == b.id,
      join: c in User, on: a.user_id == c.id,
      join: d in Ward, on: a.ward_id == d.id,
      join: e in LocalGovernment, on: a.lg_id == e.id,
      join: f in State, on: a.state_id == f.id,
      where: a.ward_id in subquery(ward_ids_subquery),
      select: %{
        user_id: a.user_id,
        partagent: c.full_name,
        ward_name: d.name,
        ward_code: d.code,
        pu_name: b.name,
        pu_code: b.code,
        lg_name: e.name,
        lg_code: e.code,
        state_name: f.name,
        state_code: f.code,
        payload: a.payload,
        upload_url: a.upload_url,
        created_at: a.created_at
      }
    )
    |> Repo.all()
  end

  def count_expected_for_supervisor(supervisor_id) do
    ward_ids_subquery = ward_ids_query(supervisor_id)

    from(p in PollingUnit,
      where: p.ward_id in subquery(ward_ids_subquery),
      select: count(p.id)
    )
    |> Repo.one()
  end

  @doc false
  def latest_created_at(results) do
    results
    |> Enum.map(& &1.created_at)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> nil
      dates -> Enum.max(dates)
    end
  end

  defp ward_ids_query(supervisor_id) do
    from(s in "supervisor_ward_assignments",
      where: s.supervisor_id == ^supervisor_id,
      select: s.ward_id
    )
  end
end
