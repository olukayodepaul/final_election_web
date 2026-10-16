# lib/web_api_election/reporting/election_result_report_ec8a_query.ex
defmodule WebApiElection.Reporting.ElectionResultReportEC8AQuery do
  import Ecto.Query
  alias WebApiElection.Repo
  alias WebApiElection.Reporting.PollingUnitEc8aReport
  alias WebApiElection.Locations.PollingUnit

  def insert_report(attrs) do
    %{
      user_id: user_id,
      election_id: election_id,
      pu_id_device: pu_id_device
    } = attrs

    case Repo.get_by(PollingUnitEc8aReport,
           user_id: user_id,
           election_id: election_id,
           pu_id_device: pu_id_device
         ) do
      nil ->
        %PollingUnitEc8aReport{}
        |> PollingUnitEc8aReport.changeset(attrs)
        |> Repo.insert()

      existing ->
        {:error, :already_exists, existing}
    end
  end

  @doc """
  Flat list of every report under a manager, for a single election.
  No joins — all fields are denormalized on the row.
  """
  def fetch_results_for_manager(manager_id, election_id) do
    from(a in PollingUnitEc8aReport,
      where: a.manager_id == ^manager_id,
      where: a.election_id == ^election_id,
      select: %{
        user_id: a.user_id,
        user_name: a.user_name,
        state: a.state,
        state_code: a.state_code,
        local_government: a.local_government,
        lg_code: a.lg_code,
        ward: a.ward,
        ward_code: a.ward_code,
        polling_unit: a.polling_unit,
        pu_code: a.pu_code,
        election_id: a.election_id,
        election_name: a.election_name,
        party_results: a.party_results,
        registered_voters: a.registered_voters,
        accredited_voters: a.accredited_voters,
        ballot_papers_issued: a.ballot_papers_issued,
        spoiled_ballots: a.spoiled_ballots,
        rejected_votes: a.rejected_votes,
        valid_votes: a.valid_votes,
        total_votes_cast: a.total_votes_cast,
        presiding_officer_name: a.presiding_officer_name,
        presiding_officer_signed: a.presiding_officer_signed,
        agent_signatures_present: a.agent_signatures_present,
        result_sheet_complete: a.result_sheet_complete,
        upload_url: a.upload_url,
        inserted_at: a.inserted_at
      }
    )
    |> Repo.all()
  end

  @doc """
  Total number of polling units expected to report under this manager.
  Same value regardless of election_id (PUs don't change per race) —
  the one join we still allow, run once, not per report row.
  """
  def count_expected_for_manager(manager_id) do
    ward_ids_subquery = ward_ids_query(manager_id)

    from(p in PollingUnit,
      where: p.ward_id in subquery(ward_ids_subquery),
      select: count(p.id)
    )
    |> Repo.one()
  end

  @doc """
  Manager-level overview for one election. Takes the already-fetched
  `results` list (from fetch_results_for_manager/2) so callers that
  need both the raw list AND the overview only query the reports once.
  """
  def manager_overview(results, manager_id) do
    expected = count_expected_for_manager(manager_id)

    totals =
      results
      |> build_totals()
      |> Map.put(:expected_pu_count, expected)

    %{
      totals: totals,
      latest_inserted_at: latest_inserted_at(results)
    }
  end

  @doc """
  Safe default shape for :ec8a_overview before any election has been
  loaded, matching exactly what manager_overview/2 returns.
  """
  def empty_overview do
    %{
      totals: %{
        reports_count: 0,
        distinct_pu_count: 0,
        users_reporting_count: 0,
        registered_voters: 0,
        accredited_voters: 0,
        ballot_papers_issued: 0,
        spoiled_ballots: 0,
        rejected_votes: 0,
        valid_votes: 0,
        total_votes_cast: 0,
        signed_count: 0,
        complete_count: 0,
        party_results: %{},
        expected_pu_count: 0
      },
      latest_inserted_at: nil
    }
  end

  defp build_totals(results) do
    init = %{
      reports_count: 0,
      distinct_pu_count: 0,
      users_reporting_count: 0,
      registered_voters: 0,
      accredited_voters: 0,
      ballot_papers_issued: 0,
      spoiled_ballots: 0,
      rejected_votes: 0,
      valid_votes: 0,
      total_votes_cast: 0,
      signed_count: 0,
      complete_count: 0,
      party_results: %{}
    }

    {totals, user_ids, pu_ids} =
      Enum.reduce(results, {init, MapSet.new(), MapSet.new()}, fn r, {acc, user_ids, pu_ids} ->
        acc = %{
          acc
          | reports_count: acc.reports_count + 1,
            registered_voters: acc.registered_voters + (r.registered_voters || 0),
            accredited_voters: acc.accredited_voters + (r.accredited_voters || 0),
            ballot_papers_issued: acc.ballot_papers_issued + (r.ballot_papers_issued || 0),
            spoiled_ballots: acc.spoiled_ballots + (r.spoiled_ballots || 0),
            rejected_votes: acc.rejected_votes + (r.rejected_votes || 0),
            valid_votes: acc.valid_votes + (r.valid_votes || 0),
            total_votes_cast: acc.total_votes_cast + (r.total_votes_cast || 0),
            signed_count: acc.signed_count + bool_to_int(r.presiding_officer_signed),
            complete_count: acc.complete_count + bool_to_int(r.result_sheet_complete),
            party_results: merge_party_results(acc.party_results, r.party_results)
        }

        {acc, MapSet.put(user_ids, r.user_id), MapSet.put(pu_ids, r.pu_code)}
      end)

    %{
      totals
      | users_reporting_count: MapSet.size(user_ids),
        distinct_pu_count: MapSet.size(pu_ids)
    }
  end

  defp merge_party_results(acc, nil), do: acc

  defp merge_party_results(acc, party_map) do
    Map.merge(acc, party_map, fn _party, v1, v2 -> to_number(v1) + to_number(v2) end)
  end

  defp bool_to_int(true), do: 1
  defp bool_to_int(_), do: 0

  defp to_number(v) when is_integer(v), do: v
  defp to_number(v) when is_float(v), do: v
  defp to_number(v) when is_binary(v), do: String.to_integer(v)
  defp to_number(_), do: 0

  @doc false
  def latest_inserted_at(results) do
    results
    |> Enum.map(& &1.inserted_at)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> nil
      dates -> Enum.max(dates)
    end
  end

  defp ward_ids_query(manager_id) do
    from(s in "supervisor_ward_assignments",
      where: s.supervisor_id == ^manager_id,
      select: s.ward_id
    )
  end
end
