# lib/web_api_election/reporting/election_collation_query.ex
defmodule WebApiElection.Reporting.ElectionCollationQuery do
  @moduledoc """
  Query + aggregation for the election-N result page (cards, pie, party table,
  ward table, PU list). Kept separate from ElectionResultReportEC8AQuery.

  One DB read for the manager's reports (one election), one for the manager's
  wards and their expected PU counts. Everything else (per-ward scoping,
  totals, party shares) is pure Elixir over the loaded list, so selecting a
  ward in the UI costs no extra query.

  Wards are identified by `ward_id` (the wards table id) on every report.
  """
  import Ecto.Query
  alias WebApiElection.Repo
  alias WebApiElection.Reporting.PollingUnitEc8aReport
  alias WebApiElection.Locations.PollingUnit

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Loads everything the page needs for one manager + one election.
  Returns %{reports, ward_rows, expected_total, unmatched_count, latest_inserted_at}.
  `unmatched_count` = reports with no ward_id (e.g. rows saved before ward_id existed).
  """
  def load(manager_id, election_id) do
    reports = fetch_reports(manager_id, election_id)
    wards = assigned_wards(manager_id)

    %{
      reports: reports,
      ward_rows: build_ward_rows(wards, reports),
      expected_total: wards |> Enum.map(& &1.expected) |> Enum.sum(),
      unmatched_count: Enum.count(reports, &is_nil(&1.ward_id)),
      latest_inserted_at: latest_inserted_at(reports)
    }
  end

  @doc "nil ward = all reports; otherwise only that ward_id."
  def filter_ward(reports, nil), do: reports
  def filter_ward(reports, ward_id), do: Enum.filter(reports, &(&1.ward_id == ward_id))

  @doc """
  Totals and party breakdown for a list of reports (whole manager or one ward).
  Party share is the party's votes divided by the sum of all party votes.
  """
  def summarize(reports) do
    party_totals = Enum.reduce(reports, %{}, &merge_party_results(&2, &1.party_results))
    party_votes = party_totals |> Map.values() |> Enum.sum()

    parties =
      party_totals
      |> Enum.map(fn {party, votes} ->
        %{party: party, votes: votes, pct: pct(votes, party_votes)}
      end)
      |> Enum.sort_by(& &1.votes, :desc)

    %{
      reports_count: length(reports),
      pu_count: reports |> Enum.map(&(&1.pu_id || {:code, &1.pu_code})) |> Enum.uniq() |> length(),
      registered_voters: sum_field(reports, :registered_voters),
      accredited_voters: sum_field(reports, :accredited_voters),
      valid_votes: sum_field(reports, :valid_votes),
      total_votes_cast: sum_field(reports, :total_votes_cast),
      party_votes: party_votes,
      parties: parties
    }
  end

  @doc "One row per polling unit report, for the selected ward's PU list."
  def pu_rows(reports) do
    reports
    |> Enum.map(fn r ->
      %{
        pu_code: r.pu_code,
        polling_unit: r.polling_unit,
        valid_votes: r.valid_votes || 0,
        total_votes_cast: r.total_votes_cast || 0,
        leader: r.party_results |> party_totals() |> leader()
      }
    end)
    |> Enum.sort_by(&(&1.polling_unit || ""))
  end

  @doc "Name of the party with the most votes, or nil when there are none."
  def leader(parties) when is_list(parties) do
    case parties do
      [%{party: party} | _] -> party
      _ -> nil
    end
  end

  def leader(party_map) when is_map(party_map) do
    party_map
    |> Enum.map(fn {party, votes} -> %{party: party, votes: votes} end)
    |> Enum.sort_by(& &1.votes, :desc)
    |> leader()
  end

  # ---------------------------------------------------------------------------
  # Queries
  # ---------------------------------------------------------------------------

  defp fetch_reports(manager_id, election_id) do
    from(a in PollingUnitEc8aReport,
      where: a.manager_id == ^manager_id,
      where: a.election_id == ^election_id,
      select: %{
        user_id: a.user_id,
        ward_id: a.ward_id,
        pu_id: a.pu_id,
        ward: a.ward,
        ward_code: a.ward_code,
        polling_unit: a.polling_unit,
        pu_code: a.pu_code,
        party_results: a.party_results,
        registered_voters: a.registered_voters,
        accredited_voters: a.accredited_voters,
        valid_votes: a.valid_votes,
        total_votes_cast: a.total_votes_cast,
        inserted_at: a.inserted_at
      }
    )
    |> Repo.all()
  end

  # ASSUMPTION: a "wards" table with columns id and name.
  # If your table/columns are named differently, change them here only.
  defp assigned_wards(manager_id) do
    ward_ids =
      from(s in "supervisor_ward_assignments",
        where: s.supervisor_id == ^manager_id,
        select: s.ward_id
      )

    wards =
      from(w in "wards",
        where: w.id in subquery(ward_ids),
        select: %{id: w.id, name: w.name}
      )
      |> Repo.all()

    expected_by_ward_id =
      from(p in PollingUnit,
        where: p.ward_id in subquery(ward_ids),
        group_by: p.ward_id,
        select: {p.ward_id, count(p.id)}
      )
      |> Repo.all()
      |> Map.new()

    Enum.map(wards, fn w ->
      %{
        ward_id: w.id,
        name: w.name,
        expected: Map.get(expected_by_ward_id, w.id, 0)
      }
    end)
  end

  # ---------------------------------------------------------------------------
  # Aggregation helpers
  # ---------------------------------------------------------------------------

  # One row per assigned ward, including wards with no reports yet.
  defp build_ward_rows(wards, reports) do
    by_ward = Enum.group_by(reports, & &1.ward_id)

    wards
    |> Enum.map(fn w ->
      summary = by_ward |> Map.get(w.ward_id, []) |> summarize()

      %{
        ward_id: w.ward_id,
        name: w.name,
        expected: w.expected,
        uploaded: summary.pu_count,
        total_votes_cast: summary.total_votes_cast,
        leader: leader(summary.parties)
      }
    end)
    |> Enum.sort_by(&(&1.name || ""))
  end

  defp party_totals(party_results), do: merge_party_results(%{}, party_results)

  defp merge_party_results(acc, nil), do: acc

  defp merge_party_results(acc, party_map) do
    Map.merge(acc, party_map, fn _party, v1, v2 -> to_number(v1) + to_number(v2) end)
    |> Map.new(fn {party, v} -> {party, to_number(v)} end)
  end

  defp sum_field(reports, field) do
    Enum.reduce(reports, 0, fn r, acc -> acc + (Map.get(r, field) || 0) end)
  end

  defp pct(_votes, 0), do: 0.0
  defp pct(votes, total), do: Float.round(votes / total * 100, 2)

  defp latest_inserted_at(reports) do
    reports
    |> Enum.map(& &1.inserted_at)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> nil
      dates -> Enum.max(dates, NaiveDateTime)
    end
  end

  defp to_number(v) when is_integer(v), do: v
  defp to_number(v) when is_float(v), do: trunc(v)

  defp to_number(v) when is_binary(v) do
    case Integer.parse(v) do
      {n, _} -> n
      :error -> 0
    end
  end

  defp to_number(_), do: 0
end
