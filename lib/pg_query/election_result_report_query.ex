
# lib/web_api_election/reporting/election_result_report_query.ex
defmodule WebApiElection.Reporting.ElectionResultReportQuery do
  alias WebApiElection.Repo
  alias WebApiElection.Reporting.ElectionResultReport

  def insert_report(attrs) do
    %ElectionResultReport{}
    |> ElectionResultReport.changeset(attrs)
    |> Repo.insert()
  end
end
