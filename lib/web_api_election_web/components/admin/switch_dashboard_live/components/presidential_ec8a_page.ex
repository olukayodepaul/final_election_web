defmodule WebApiElectionWeb.Admin.SwitchDashboardLive.Components.Elections.PresidentialEC8APage do
  use WebApiElectionWeb, :html

  attr :overview, :any, required: true
  attr :results, :any, required: true
  attr :election_name, :string, default: nil

  def presidential_ec8a_page(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-lg font-semibold text-slate-900">Presidential EC8A</h2>
          <p class="text-[13px] text-slate-500">
            Polling unit results uploaded by field agents under your team.
          </p>
        </div>
      </div>

      <.async_result :let={overview} assign={@overview}>
        <:loading>
          <div class="flex items-center gap-2 text-sm text-slate-500 py-10 justify-center">
            <svg class="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="9" stroke-opacity="0.25" />
              <path d="M21 12a9 9 0 00-9-9" />
            </svg>
            Loading overview…
          </div>
        </:loading>

        <:failed :let={_reason}>
          <div class="flex items-center gap-2 text-sm text-rose-500 py-10 justify-center">
            <.icon name="hero-exclamation-triangle" class="h-4 w-4" />
            Failed to load overview.
          </div>
        </:failed>

        <% totals = overview.totals %>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <div class="border border-slate-200 rounded-xl p-5 bg-white shadow-sm">
            <h3 class="text-[13px] font-semibold text-slate-500 mb-3">Result Stats</h3>
            <div class="border-t border-slate-100 pt-3">
              <p class="text-[12px] text-slate-500">Polling units reported</p>
              <p class="text-3xl font-bold text-slate-900">{totals.distinct_pu_count}</p>
            </div>
            <div class="border-t border-slate-100 mt-3 pt-3">
              <p class="text-[13px] font-medium text-slate-700">Out of {totals.expected_pu_count}</p>
            </div>
          </div>

          <div class="border border-slate-200 rounded-xl p-5 bg-white shadow-sm">
            <h3 class="text-[13px] font-semibold text-slate-500 mb-4">Uploaded results</h3>
            <div class="space-y-3">
              <div>
                <div class="flex justify-between text-[12px] text-slate-500 mb-1">
                  <span>Uploaded</span>
                  <span class="font-mono">{totals.distinct_pu_count}</span>
                </div>
                <div class="h-3 rounded-full bg-slate-100 overflow-hidden">
                  <div
                    class="h-full bg-emerald-500 rounded-full"
                    style={"width: #{bar_pct(totals.distinct_pu_count, totals.expected_pu_count)}%"}
                  >
                  </div>
                </div>
              </div>
              <div>
                <div class="flex justify-between text-[12px] text-slate-500 mb-1">
                  <span>Expected</span>
                  <span class="font-mono">{totals.expected_pu_count}</span>
                </div>
                <div class="h-3 rounded-full bg-slate-100 overflow-hidden">
                  <div class="h-full bg-slate-800 rounded-full" style="width: 100%"></div>
                </div>
              </div>
            </div>
          </div>

          <div class="rounded-xl p-5 bg-emerald-600 text-white shadow-sm flex flex-col justify-between">
            <div>
              <p class="text-[13px] text-emerald-100">Percentage uploaded</p>
              <p class="text-3xl font-bold">{bar_pct(totals.distinct_pu_count, totals.expected_pu_count)}%</p>
            </div>
            <div class="mt-4 pt-3 border-t border-emerald-500/40 text-[12px] text-emerald-100">
              <p>Last upload time</p>
              <p class="font-medium text-white">{format_last_upload(overview.latest_inserted_at)}</p>
            </div>
          </div>
        </div>

        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div class="border border-slate-200 rounded-xl p-4 bg-white shadow-sm">
            <p class="text-[12px] text-slate-500">Agents Reporting</p>
            <p class="text-xl font-bold text-slate-900">{totals.users_reporting_count}</p>
          </div>
          <div class="border border-slate-200 rounded-xl p-4 bg-white shadow-sm">
            <p class="text-[12px] text-slate-500">Total Votes Cast</p>
            <p class="text-xl font-bold text-slate-900">{totals.total_votes_cast}</p>
          </div>
          <div class="border border-slate-200 rounded-xl p-4 bg-white shadow-sm">
            <p class="text-[12px] text-slate-500">Signed Sheets</p>
            <p class="text-xl font-bold text-slate-900">{totals.signed_count}</p>
          </div>
          <div class="border border-slate-200 rounded-xl p-4 bg-white shadow-sm">
            <p class="text-[12px] text-slate-500">Complete Sheets</p>
            <p class="text-xl font-bold text-slate-900">{totals.complete_count}</p>
          </div>
        </div>
      </.async_result>

      <.async_result :let={results} assign={@results}>
        <:loading>
          <div class="flex items-center gap-2 text-sm text-slate-500 py-10 justify-center">
            <svg class="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="9" stroke-opacity="0.25" />
              <path d="M21 12a9 9 0 00-9-9" />
            </svg>
            Loading results…
          </div>
        </:loading>

        <:failed :let={_reason}>
          <div class="flex items-center gap-2 text-sm text-rose-500 py-10 justify-center">
            <.icon name="hero-exclamation-triangle" class="h-4 w-4" />
            Failed to load results.
          </div>
        </:failed>

        <div :if={results == []} class="flex flex-col items-center justify-center gap-2 py-16 text-center border border-dashed border-slate-200 rounded-xl bg-slate-50/50">
          <.icon name="hero-inbox" class="h-8 w-8 text-slate-300" />
          <p class="text-sm text-slate-500">No results have been uploaded yet.</p>
        </div>

        <div :if={results != []} class="overflow-hidden border border-slate-200 rounded-xl shadow-sm">
          <div class="overflow-x-auto">
            <table class="min-w-full text-[13px]">
              <thead class="bg-slate-50 text-left text-slate-500 border-b border-slate-200">
                <tr>
                  <th class="px-4 py-3 font-medium">Party Agent</th>
                  <th class="px-4 py-3 font-medium">State</th>
                  <th class="px-4 py-3 font-medium">LGA</th>
                  <th class="px-4 py-3 font-medium">Ward</th>
                  <th class="px-4 py-3 font-medium">Polling Unit</th>
                  <th class="px-4 py-3 font-medium text-right">Result</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100">
                <tr :for={row <- results} class="hover:bg-slate-50 transition-colors">
                  <td class="px-4 py-3 font-medium text-slate-800">{row.user_name}</td>

                  <td class="px-4 py-3">
                    <div class="leading-tight">
                      <div class="text-slate-700">{row.state}</div>
                      <div class="text-[11px] text-slate-400 font-mono">{row.state_code}</div>
                    </div>
                  </td>

                  <td class="px-4 py-3">
                    <div class="leading-tight">
                      <div class="text-slate-700">{row.local_government}</div>
                      <div class="text-[11px] text-slate-400 font-mono">{row.lg_code}</div>
                    </div>
                  </td>

                  <td class="px-4 py-3">
                    <div class="leading-tight">
                      <div class="text-slate-700">{row.ward}</div>
                      <div class="text-[11px] text-slate-400 font-mono">{row.ward_code}</div>
                    </div>
                  </td>

                  <td class="px-4 py-3">
                    <div class="leading-tight">
                      <div class="text-slate-700">{row.polling_unit}</div>
                      <div class="text-[11px] text-slate-400 font-mono">{row.pu_code}</div>
                    </div>
                  </td>

                  <td class="px-4 py-3 text-right">
                   <button
                      type="button"
                      phx-click="open-election-result-modal"
                      phx-value-user_id={row.user_id}
                      class="inline-flex items-center gap-1.5 rounded-lg bg-emerald-600 px-3 py-1.5 text-[12px] font-medium text-white shadow-sm hover:bg-emerald-700 active:bg-emerald-800 transition-colors"
                    >
                      <.icon name="hero-eye" class="h-3.5 w-3.5" />
                      View
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </.async_result>
    </div>
    """
  end

  defp bar_pct(_uploaded, nil), do: 0
  defp bar_pct(_uploaded, 0), do: 0
  defp bar_pct(uploaded, expected), do: min(100, Float.round(uploaded / expected * 100, 1))

  defp format_last_upload(nil), do: "—"

  defp format_last_upload(%mod{} = dt) when mod in [DateTime, NaiveDateTime],
    do: Calendar.strftime(dt, "%b %-d, %Y, %-I:%M:%S %p")
end
