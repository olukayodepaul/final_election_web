# lib/web_api_election_web/live/admin/switch_dashboard_live/components/election_result_modal.ex
defmodule WebApiElectionWeb.Admin.SwitchDashboardLive.Components.ElectionResultModal do
  use WebApiElectionWeb, :html

  attr :record, :any, required: true

  def election_result_modal(assigns) do
    assigns = assign(assigns, :parties, top_parties(assigns.record[:party_results]))

    ~H"""
    <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
      <div class="bg-white rounded-xl shadow-xl w-full max-w-5xl max-h-[88vh] overflow-y-auto">
        <div class="flex items-center justify-between px-6 py-4 border-b border-slate-200">
          <div>
            <h3 class="text-[15px] font-semibold text-slate-900">{@record[:polling_unit]}</h3>
            <p class="text-[12px] text-slate-500">
              {@record[:ward]}, {@record[:local_government]}, {@record[:state]}
            </p>
          </div>
          <button
            type="button"
            phx-click="close-election-result-modal"
            class="text-slate-400 hover:text-slate-600 transition-colors"
          >
            <.icon name="hero-x-mark" class="h-5 w-5" />
          </button>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 p-6">
          <div class="space-y-2">
            <.result_photo upload_url={@record[:upload_url]} polling_unit={@record[:polling_unit]} />
            <p class="text-[11px] text-slate-400">
              PU {@record[:pu_code]} - Tap image to view full size
            </p>
          </div>

          <div class="space-y-6">
            <div class="flex flex-wrap gap-2">
              <.status_badge label="Presiding officer signed" ok={@record[:presiding_officer_signed]} />
              <.status_badge label="Agent signatures present" ok={@record[:agent_signatures_present]} />
              <.status_badge label="Result sheet complete" ok={@record[:result_sheet_complete]} />
            </div>

            <div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
              <.stat label="Registered" value={@record[:registered_voters]} />
              <.stat label="Accredited" value={@record[:accredited_voters]} />
              <.stat label="Ballots issued" value={@record[:ballot_papers_issued]} />
              <.stat label="Spoiled" value={@record[:spoiled_ballots]} />
              <.stat label="Rejected" value={@record[:rejected_votes]} />
              <.stat label="Valid" value={@record[:valid_votes]} />
            </div>

            <div class="rounded-lg bg-slate-900 text-white px-4 py-3 flex items-center justify-between">
              <span class="text-[12px] text-slate-300">Total votes cast</span>
              <span class="text-xl font-bold">{@record[:total_votes_cast]}</span>
            </div>

            <div>
              <h4 class="text-[13px] font-semibold text-slate-700 mb-3">Party results</h4>
              <div class="space-y-2">
                <div :for={{party, votes, pct} <- @parties.shown} class="flex items-center gap-3">
                  <span class="w-12 shrink-0 text-[13px] font-semibold text-slate-800">{party}</span>
                  <div class="flex-1 h-6 rounded bg-slate-100 overflow-hidden">
                    <div
                      class={[
                        "h-full rounded flex items-center justify-end px-2",
                        party == @parties.leader && "bg-emerald-600",
                        party != @parties.leader && "bg-slate-400"
                      ]}
                      style={"width: #{max(pct, 6)}%"}
                    >
                    </div>
                  </div>
                  <span class="w-12 shrink-0 text-right text-[13px] font-mono text-slate-700">{votes}</span>
                </div>
              </div>
              <p :if={@parties.zero_count > 0} class="text-[12px] text-slate-400 mt-2">
                + {@parties.zero_count} other {if @parties.zero_count == 1, do: "party", else: "parties"} with 0 votes
              </p>
            </div>

            <div class="border-t border-slate-100 pt-3 text-[12px] text-slate-500 space-y-1">
              <p>Presiding officer: <span class="text-slate-700">{@record[:presiding_officer_name]}</span></p>
              <p>Submitted by: <span class="text-slate-700">{@record[:user_name]}</span></p>
              <p>Submitted at: <span class="text-slate-700">{format_datetime(@record[:inserted_at])}</span></p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :upload_url, :any, required: true
  attr :polling_unit, :any, required: true

  defp result_photo(assigns) do
    ~H"""
    <div :if={@upload_url} class="rounded-lg border border-slate-200 overflow-hidden bg-slate-50">
      <img
        src={@upload_url}
        alt={"Result sheet - #{@polling_unit}"}
        class="w-full h-auto object-contain max-h-[70vh]"
      />
    </div>
    <div
      :if={!@upload_url}
      class="flex items-center justify-center h-64 rounded-lg border border-slate-200 bg-slate-50 text-slate-400 text-[13px]"
    >
      No result sheet image uploaded
    </div>
    """
  end

  attr :label, :string, required: true
  attr :ok, :any, required: true

  defp status_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[12px] font-medium",
      @ok && "bg-emerald-50 text-emerald-700",
      !@ok && "bg-rose-50 text-rose-700"
    ]}>
      <.icon name={if @ok, do: "hero-check-circle", else: "hero-x-circle"} class="h-3.5 w-3.5" />
      {@label}
    </span>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true

  defp stat(assigns) do
    ~H"""
    <div class="border border-slate-200 rounded-lg p-3">
      <p class="text-[11px] text-slate-500">{@label}</p>
      <p class="text-lg font-bold text-slate-900">{@value || 0}</p>
    </div>
    """
  end

  # Sorts party_results descending, drops zero-vote parties from the
  # chart (counted separately instead), and computes each bar's width
  # as a percentage of the leading party's vote count.
  defp top_parties(nil), do: %{shown: [], leader: nil, zero_count: 0}

  defp top_parties(party_results) do
    sorted =
      party_results
      |> Enum.map(fn {party, votes} -> {party, to_number(votes)} end)
      |> Enum.sort_by(fn {_party, votes} -> votes end, :desc)

    {with_votes, zero_votes} = Enum.split_with(sorted, fn {_party, votes} -> votes > 0 end)

    max_votes =
      case with_votes do
        [{_party, top} | _] -> top
        [] -> 0
      end

    shown =
      Enum.map(with_votes, fn {party, votes} ->
        pct = if max_votes > 0, do: votes / max_votes * 100, else: 0
        {party, votes, pct}
      end)

    leader =
      case shown do
        [{party, _votes, _pct} | _] -> party
        [] -> nil
      end

    %{shown: shown, leader: leader, zero_count: length(zero_votes)}
  end

  defp to_number(v) when is_integer(v), do: v
  defp to_number(v) when is_float(v), do: v
  defp to_number(v) when is_binary(v), do: String.to_integer(v)
  defp to_number(_), do: 0

  defp format_datetime(nil), do: "-"

  defp format_datetime(%mod{} = dt) when mod in [DateTime, NaiveDateTime],
    do: Calendar.strftime(dt, "%b %-d, %Y, %-I:%M %p")

  defp format_datetime(_), do: "-"
end
