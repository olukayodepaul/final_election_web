defmodule WebApiElectionWeb.Admin.SwitchDashboardLive.Components.Elections.PresidentialPage do
  @moduledoc """
  Presidential result page for a manager: two leading-party cards, vote-share
  pie, party table, ward table and (when a ward is selected) its PU list.

  Replaces the earlier mock version. Same module name and function name
  (`presidential_page/1`), so the existing import keeps working.
  """
  use Phoenix.Component
  alias WebApiElection.Reporting.ElectionCollationQuery

  @party_colors %{
    "APC" => "#0ea5e9",
    "PDP" => "#059669",
    "LP" => "#e11d48",
    "NNPP" => "#f59e0b",
    "APGA" => "#6366f1",
    "SDP" => "#f97316",
    "ADC" => "#0d9488",
    "YPP" => "#c026d3",
    "OTHERS" => "#94a3b8"
  }
  @fallback_colors ["#64748b", "#a855f7", "#84cc16", "#06b6d4", "#ef4444", "#eab308"]

  attr :collation, :any, required: true, doc: "Phoenix.LiveView.AsyncResult wrapping the load/2 map"
  attr :selected_ward, :any, default: nil
  attr :election_name, :string, default: "Presidential"

  def presidential_page(assigns) do
    ~H"""
    <.async_result :let={data} assign={@collation}>
      <:loading>
        <div class="py-16 text-center text-sm text-gray-500 dark:text-slate-400">
          Loading results…
        </div>
      </:loading>
      <:failed :let={_failure}>
        <div class="py-16 text-center text-sm text-rose-600">
          Results could not be loaded. Refresh the page to try again.
        </div>
      </:failed>

      <.collation_body data={data} selected_ward={@selected_ward} election_name={@election_name} />
    </.async_result>
    """
  end

  attr :data, :map, required: true
  attr :selected_ward, :any, default: nil
  attr :election_name, :string, required: true

  defp collation_body(assigns) do
    scoped = ElectionCollationQuery.filter_ward(assigns.data.reports, assigns.selected_ward)
    summary = ElectionCollationQuery.summarize(scoped)
    selected_row = Enum.find(assigns.data.ward_rows, &(&1.ward_id == assigns.selected_ward))

    assigns =
      assigns
      |> assign(:summary, summary)
      |> assign(:selected_row, selected_row)
      |> assign(:pie, pie_segments(summary.parties))
      |> assign(:top_two, summary.parties |> Enum.take(2) |> Enum.with_index())
      |> assign(:pu_rows, if(assigns.selected_ward, do: ElectionCollationQuery.pu_rows(scoped), else: []))
      |> assign(
        :expected,
        if(selected_row, do: selected_row.expected, else: assigns.data.expected_total)
      )

    ~H"""
    <div class="space-y-6">
      <!-- Title + scope -->
      <div class="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 class="text-xl font-semibold text-gray-900 dark:text-slate-100">
            {@election_name} election results
          </h1>
          <p class="mt-1 text-sm text-gray-500 dark:text-slate-400">
            Showing {if @selected_row, do: @selected_row.name, else: "all your wards"}
            · {fmt(@summary.pu_count)} of {fmt(@expected)} polling units reported
          </p>
        </div>
        <button
          :if={@selected_ward}
          phx-click="clear-collation-ward"
          class="rounded-lg border border-gray-200 px-3 py-1.5 text-[13px] font-medium text-gray-700 hover:bg-gray-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-900"
        >
          Show all wards
        </button>
      </div>

      <div
        :if={@summary.parties == []}
        class="rounded-xl border border-dashed border-gray-300 p-10 text-center text-sm text-gray-500 dark:border-slate-700 dark:text-slate-400"
      >
        No results uploaded yet {if @selected_row, do: "for this ward", else: "for this election"}.
      </div>

      <div :if={@summary.parties != []} class="space-y-6">
        <!-- Top two parties -->
        <div class="grid gap-4 md:grid-cols-2">
          <div
            :for={{p, i} <- @top_two}
            class="rounded-xl border border-gray-200 bg-white p-5 dark:border-slate-800 dark:bg-slate-900/40"
            style={"border-left: 4px solid #{party_color(p.party, i)}"}
          >
            <div class="flex items-baseline justify-between">
              <div class="text-lg font-semibold text-gray-900 dark:text-slate-100">{p.party}</div>
              <div class="text-sm text-gray-500 dark:text-slate-400">
                {if i == 0, do: "Leading", else: "Second"}
              </div>
            </div>
            <div class="mt-3 flex items-end gap-6">
              <div>
                <div class="text-3xl font-semibold tabular-nums text-gray-900 dark:text-slate-100">
                  {fmt(p.votes)}
                </div>
                <div class="text-xs text-gray-500 dark:text-slate-400">votes</div>
              </div>
              <div>
                <div class="text-3xl font-semibold tabular-nums" style={"color: #{party_color(p.party, i)}"}>
                  {p.pct}%
                </div>
                <div class="text-xs text-gray-500 dark:text-slate-400">share of votes</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Pie + party table -->
        <div class="grid gap-6 lg:grid-cols-[280px_1fr]">
          <div class="flex flex-col items-center rounded-xl border border-gray-200 bg-white p-5 dark:border-slate-800 dark:bg-slate-900/40">
            <svg viewBox="0 0 42 42" class="h-48 w-48" role="img" aria-label="Vote share by party">
              <circle
                cx="21"
                cy="21"
                r="15.91549430918954"
                fill="none"
                stroke="#e2e8f0"
                stroke-width="6"
                class="dark:stroke-slate-800"
              />
              <circle
                :for={seg <- @pie}
                cx="21"
                cy="21"
                r="15.91549430918954"
                fill="none"
                stroke={seg.color}
                stroke-width="6"
                stroke-dasharray={seg.dash}
                stroke-dashoffset={seg.offset}
              />
            </svg>
            <ul class="mt-4 w-full space-y-1.5 text-[13px]">
              <li :for={seg <- @pie} class="flex items-center justify-between gap-3">
                <span class="flex items-center gap-2 text-gray-700 dark:text-slate-300">
                  <span class="h-2.5 w-2.5 rounded-sm" style={"background: #{seg.color}"}></span>
                  {seg.party}
                </span>
                <span class="tabular-nums text-gray-500 dark:text-slate-400">{seg.pct}%</span>
              </li>
            </ul>
          </div>

          <div class="overflow-x-auto rounded-xl border border-gray-200 bg-white dark:border-slate-800 dark:bg-slate-900/40">
            <table class="w-full text-left text-[14px]">
              <thead class="border-b border-gray-200 text-[13px] text-gray-500 dark:border-slate-800 dark:text-slate-400">
                <tr>
                  <th class="px-4 py-3 font-medium">Party</th>
                  <th class="px-4 py-3 text-right font-medium">Votes</th>
                  <th class="px-4 py-3 text-right font-medium">Share</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 dark:divide-slate-800">
                <tr :for={{p, i} <- Enum.with_index(@summary.parties)}>
                  <td class="px-4 py-2.5">
                    <span class="flex items-center gap-2 text-gray-900 dark:text-slate-100">
                      <span class="h-2.5 w-2.5 rounded-sm" style={"background: #{party_color(p.party, i)}"}></span>
                      {p.party}
                    </span>
                  </td>
                  <td class="px-4 py-2.5 text-right tabular-nums">{fmt(p.votes)}</td>
                  <td class="px-4 py-2.5 text-right tabular-nums">{p.pct}%</td>
                </tr>
              </tbody>
              <tfoot class="border-t border-gray-200 text-[13px] text-gray-600 dark:border-slate-800 dark:text-slate-300">
                <tr>
                  <td class="px-4 py-2.5 font-medium">Total party votes</td>
                  <td class="px-4 py-2.5 text-right font-medium tabular-nums">{fmt(@summary.party_votes)}</td>
                  <td></td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>
      </div>

      <!-- Ward table -->
      <div class="overflow-x-auto rounded-xl border border-gray-200 bg-white dark:border-slate-800 dark:bg-slate-900/40">
        <div class="border-b border-gray-200 px-4 py-3 text-[14px] font-medium text-gray-900 dark:border-slate-800 dark:text-slate-100">
          Results by ward
          <span class="ml-2 text-[13px] font-normal text-gray-500 dark:text-slate-400">
            Select a ward to see its numbers above
          </span>
        </div>
        <table class="w-full text-left text-[14px]">
          <thead class="border-b border-gray-200 text-[13px] text-gray-500 dark:border-slate-800 dark:text-slate-400">
            <tr>
              <th class="px-4 py-3 font-medium">Ward</th>
              <th class="px-4 py-3 font-medium">Polling units reported</th>
              <th class="px-4 py-3 text-right font-medium">Votes cast</th>
              <th class="px-4 py-3 font-medium">Leading party</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100 dark:divide-slate-800">
            <tr
              :for={row <- @data.ward_rows}
              phx-click="select-collation-ward"
              phx-value-ward_id={row.ward_id}
              class={[
                "cursor-pointer transition-colors hover:bg-gray-50 dark:hover:bg-slate-900",
                @selected_ward == row.ward_id && "bg-blue-50 dark:bg-blue-500/10"
              ]}
            >
              <td class="px-4 py-2.5 font-medium text-gray-900 dark:text-slate-100">{row.name}</td>
              <td class="px-4 py-2.5">
                <div class="flex items-center gap-3">
                  <div class="h-1.5 w-28 overflow-hidden rounded-full bg-gray-200 dark:bg-slate-800">
                    <div class="h-full rounded-full bg-sky-500" style={"width: #{progress(row)}%"}></div>
                  </div>
                  <span class="tabular-nums text-gray-600 dark:text-slate-300">
                    {fmt(row.uploaded)} / {fmt(row.expected)}
                  </span>
                </div>
              </td>
              <td class="px-4 py-2.5 text-right tabular-nums">{fmt(row.total_votes_cast)}</td>
              <td class="px-4 py-2.5">
                <span :if={row.leader} class="flex items-center gap-2">
                  <span class="h-2.5 w-2.5 rounded-sm" style={"background: #{party_color(row.leader, 0)}"}></span>
                  {row.leader}
                </span>
                <span :if={!row.leader} class="text-gray-400 dark:text-slate-500">No results yet</span>
              </td>
            </tr>
          </tbody>
        </table>
        <p
          :if={@data.unmatched_count > 0}
          class="border-t border-gray-200 px-4 py-3 text-[13px] text-amber-700 dark:border-slate-800 dark:text-amber-400"
        >
          {fmt(@data.unmatched_count)} report(s) have no ward. They are counted in the totals above but not in any ward row.
        </p>
      </div>

      <!-- Polling units of the selected ward -->
      <div
        :if={@selected_ward}
        class="overflow-x-auto rounded-xl border border-gray-200 bg-white dark:border-slate-800 dark:bg-slate-900/40"
      >
        <div class="border-b border-gray-200 px-4 py-3 text-[14px] font-medium text-gray-900 dark:border-slate-800 dark:text-slate-100">
          Polling units in {if @selected_row, do: @selected_row.name, else: "this ward"}
        </div>
        <div :if={@pu_rows == []} class="p-6 text-center text-sm text-gray-500 dark:text-slate-400">
          No polling unit has reported in this ward yet.
        </div>
        <table :if={@pu_rows != []} class="w-full text-left text-[14px]">
          <thead class="border-b border-gray-200 text-[13px] text-gray-500 dark:border-slate-800 dark:text-slate-400">
            <tr>
              <th class="px-4 py-3 font-medium">Polling unit</th>
              <th class="px-4 py-3 font-medium">PU code</th>
              <th class="px-4 py-3 text-right font-medium">Valid votes</th>
              <th class="px-4 py-3 text-right font-medium">Votes cast</th>
              <th class="px-4 py-3 font-medium">Leading party</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100 dark:divide-slate-800">
            <tr :for={pu <- @pu_rows}>
              <td class="px-4 py-2.5 text-gray-900 dark:text-slate-100">{pu.polling_unit}</td>
              <td class="px-4 py-2.5 tabular-nums text-gray-600 dark:text-slate-300">{pu.pu_code}</td>
              <td class="px-4 py-2.5 text-right tabular-nums">{fmt(pu.valid_votes)}</td>
              <td class="px-4 py-2.5 text-right tabular-nums">{fmt(pu.total_votes_cast)}</td>
              <td class="px-4 py-2.5">{pu.leader || "—"}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Top 5 parties + "Others", as donut segments (circumference normalised to 100).
  defp pie_segments(parties) do
    {top, rest} = Enum.split(parties, 5)
    others_votes = rest |> Enum.map(& &1.votes) |> Enum.sum()
    others_pct = rest |> Enum.map(& &1.pct) |> Enum.sum() |> Float.round(2)

    slices =
      if others_votes > 0,
        do: top ++ [%{party: "Others", votes: others_votes, pct: others_pct}],
        else: top

    {segments, _} =
      slices
      |> Enum.with_index()
      |> Enum.map_reduce(0.0, fn {s, i}, used ->
        seg = %{
          party: s.party,
          pct: s.pct,
          color: party_color(s.party, i),
          dash: "#{s.pct} #{Float.round(100 - s.pct, 2)}",
          offset: Float.round(25 - used, 2)
        }

        {seg, used + s.pct}
      end)

    segments
  end

  defp party_color(party, index) do
    Map.get(@party_colors, String.upcase(to_string(party))) ||
      Enum.at(@fallback_colors, rem(index, length(@fallback_colors)))
  end

  defp progress(%{expected: expected}) when expected in [0, nil], do: 0
  defp progress(%{uploaded: uploaded, expected: expected}), do: min(100, round(uploaded / expected * 100))

  defp fmt(n) when is_integer(n) do
    n
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end

  defp fmt(_), do: "0"
end
