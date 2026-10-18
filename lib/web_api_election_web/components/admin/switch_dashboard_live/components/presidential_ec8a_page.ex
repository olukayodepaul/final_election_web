defmodule WebApiElectionWeb.Admin.SwitchDashboardLive.Components.Elections.PresidentialEC8APage do
  use WebApiElectionWeb, :html

  alias Phoenix.LiveView.JS

  attr :officers, :any, required: true
  attr :reports, :any, default: nil
  attr :election_name, :string, default: nil

  def presidential_ec8a_page(assigns) do
    assigns = assign(assigns, :reports_by_user, reports_by_user(assigns.reports))

    ~H"""
    <div class="space-y-6">
      <%!-- Page header --%>
      <div class="flex items-center gap-3">
        <div class="h-11 w-11 rounded-2xl bg-gradient-to-br from-emerald-500 to-emerald-600 text-white flex items-center justify-center shadow-lg shadow-emerald-500/30">
          <.icon name="hero-document-chart-bar" class="h-6 w-6" />
        </div>
        <div>
          <h2 class="text-xl font-bold tracking-tight text-slate-900 dark:text-slate-100">IVotas EC8A</h2>
          <p class="text-[13px] text-slate-500 dark:text-slate-400">
            Field officers assigned to your wards and their result uploads.
          </p>
        </div>
      </div>

      <.async_result :let={officers} assign={@officers}>
        <:loading>
          <div class="flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400 py-16 justify-center">
            <svg class="h-5 w-5 animate-spin text-emerald-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="9" stroke-opacity="0.25" />
              <path d="M21 12a9 9 0 00-9-9" />
            </svg>
            Loading officers…
          </div>
        </:loading>

        <:failed :let={_reason}>
          <div class="flex items-center gap-2 text-sm text-rose-500 dark:text-rose-400 py-16 justify-center">
            <.icon name="hero-exclamation-triangle" class="h-5 w-5" />
            Failed to load officers.
          </div>
        </:failed>

        <%!-- Stat cards --%>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
          <.stat_card label="Field Officers" value={length(officers)} icon="hero-users" tone="emerald" />
          <.stat_card label="Polling Units" value={count_unique(officers, :polling_unit_id)} icon="hero-map-pin" tone="sky" />
          <.stat_card label="Wards" value={count_unique(officers, :ward_id)} icon="hero-building-office-2" tone="violet" />
          <.stat_card label="LGAs" value={count_unique(officers, :lg_id)} icon="hero-map" tone="amber" />
        </div>

        <%!-- Empty state --%>
        <div
          :if={officers == []}
          class="flex flex-col items-center justify-center gap-3 py-20 text-center border-2 border-dashed border-slate-200 dark:border-slate-700 rounded-2xl bg-slate-50/50 dark:bg-slate-900/40"
        >
          <div class="h-14 w-14 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center">
            <.icon name="hero-inbox" class="h-7 w-7 text-slate-400 dark:text-slate-500" />
          </div>
          <p class="text-sm text-slate-500 dark:text-slate-400">No field officers are assigned to your wards.</p>
        </div>

        <%!-- Officers table --%>
        <div
          :if={officers != []}
          class="overflow-hidden border border-slate-200 dark:border-slate-800 rounded-2xl shadow-sm bg-white dark:bg-slate-900"
        >
          <div class="overflow-x-auto">
            <table class="min-w-full text-[13px]">
              <thead class="bg-slate-50/80 dark:bg-slate-800/40 text-left text-[11px] uppercase tracking-wider text-slate-500 dark:text-slate-400 border-b border-slate-200 dark:border-slate-800">
                <tr>
                  <th class="px-5 py-3.5 font-semibold">Field Officer</th>
                  <th class="px-5 py-3.5 font-semibold">State</th>
                  <th class="px-5 py-3.5 font-semibold">LGA</th>
                  <th class="px-5 py-3.5 font-semibold">Ward</th>
                  <th class="px-5 py-3.5 font-semibold">Polling Unit</th>
                  <th class="px-5 py-3.5 font-semibold text-right">Registered Voters</th>
                </tr>
              </thead>

              <%!-- one <tbody> per officer keeps the row and its detail row together --%>
              <tbody
                :for={row <- officers}
                class="border-b border-slate-100 dark:border-slate-800 last:border-b-0"
              >
                <% key = "#{row.user_id}-#{row.polling_unit_id}" %>
                <% user_reports = Map.get(@reports_by_user, row.user_id, []) %>
                <% count = length(user_reports) %>

                <tr
                  id={"row-#{key}"}
                  class="group cursor-pointer hover:bg-emerald-50/40 dark:hover:bg-emerald-500/5 transition-colors"
                  phx-click={toggle_reports(key)}
                >
                  <td class="px-5 py-4">
                    <div class="flex items-center gap-3">
                      <span id={"chev-#{key}"} class="inline-flex transition-transform duration-200">
                        <.icon name="hero-chevron-right" class="h-4 w-4 text-slate-400 group-hover:text-emerald-500" />
                      </span>

                      <div class="h-9 w-9 shrink-0 rounded-full bg-gradient-to-br from-emerald-400 to-teal-500 text-white text-[12px] font-bold flex items-center justify-center shadow-sm">
                        {initials(row.user_name)}
                      </div>

                      <div class="leading-tight">
                        <div class="font-semibold text-slate-800 dark:text-slate-100">{row.user_name}</div>
                        <span class={[
                          "mt-1 inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[11px] font-medium",
                          count > 0 && "bg-emerald-100 text-emerald-700 dark:bg-emerald-500/15 dark:text-emerald-300",
                          count == 0 && "bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400"
                        ]}>
                          <.icon name="hero-document-text" class="h-3 w-3" />
                          {count} upload{if count == 1, do: "", else: "s"}
                        </span>
                      </div>
                    </div>
                  </td>

                  <td class="px-5 py-4">
                    <div class="leading-tight">
                      <div class="text-slate-700 dark:text-slate-300">{row.state_name}</div>
                      <div class="text-[11px] text-slate-400 dark:text-slate-500 font-mono">{row.state_code}</div>
                    </div>
                  </td>

                  <td class="px-5 py-4">
                    <div class="leading-tight">
                      <div class="text-slate-700 dark:text-slate-300">{row.lg_name}</div>
                      <div class="text-[11px] text-slate-400 dark:text-slate-500 font-mono">{row.lg_code}</div>
                    </div>
                  </td>

                  <td class="px-5 py-4">
                    <div class="leading-tight">
                      <div class="text-slate-700 dark:text-slate-300">{row.ward_name}</div>
                      <div class="text-[11px] text-slate-400 dark:text-slate-500 font-mono">{row.ward_code}</div>
                    </div>
                  </td>

                  <td class="px-5 py-4">
                    <div class="leading-tight">
                      <div class="text-slate-700 dark:text-slate-300">{row.pu_name}</div>
                      <div class="text-[11px] text-slate-400 dark:text-slate-500 font-mono">{row.pu_code}</div>
                    </div>
                  </td>

                  <td class="px-5 py-4 text-right font-mono font-semibold text-slate-700 dark:text-slate-300">
                    {format_number(row.registered_voters || 0)}
                  </td>
                </tr>

                <%!-- Expandable uploads list --%>
                <tr id={"reports-#{key}"} class="hidden">
                  <td colspan="6" class="p-0">
                    <div class="border-t border-emerald-100 dark:border-emerald-500/10 bg-gradient-to-b from-emerald-50/70 to-slate-50/40 dark:from-emerald-500/5 dark:to-slate-900/40 px-6 py-5">
                      <div class="mb-3 flex items-center justify-between">
                        <h4 class="text-[12px] font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                          Result uploads
                        </h4>
                        <span class="text-[11px] text-slate-400 dark:text-slate-500">
                          {count} total
                        </span>
                      </div>

                      <div
                        :if={user_reports == []}
                        class="flex flex-col items-center gap-2 rounded-xl border border-dashed border-slate-300 dark:border-slate-700 bg-white/60 dark:bg-slate-900/40 py-8 text-center"
                      >
                        <.icon name="hero-document-minus" class="h-6 w-6 text-slate-300 dark:text-slate-600" />
                        <p class="text-[13px] text-slate-500 dark:text-slate-400">No result uploads yet.</p>
                      </div>

                      <ul :if={user_reports != []} class="space-y-2.5">
                        <li
                          :for={report <- user_reports}
                          class="group/item flex items-center justify-between gap-4 rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 px-4 py-3 shadow-sm transition hover:border-emerald-300 dark:hover:border-emerald-500/40 hover:shadow-md"
                        >
                          <div class="flex min-w-0 items-center gap-3">
                            <div class="h-10 w-10 shrink-0 rounded-xl bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
                              <.icon name="hero-document-text" class="h-5 w-5" />
                            </div>
                            <div class="min-w-0 leading-tight">
                              <p class="truncate text-[14px] font-semibold text-slate-800 dark:text-slate-100">
                                {report.election_name || "Untitled election"}
                              </p>
                              <p class="mt-1 flex items-center gap-1 text-[12px] text-slate-500 dark:text-slate-400">
                                <.icon name="hero-clock" class="h-3.5 w-3.5" />
                                {format_dt(report.created_at)}
                              </p>
                            </div>
                          </div>

                          <button
                            type="button"
                            phx-click="view_report"
                            phx-value-id={report.id}
                            class="inline-flex shrink-0 items-center gap-1.5 rounded-lg bg-gradient-to-b from-emerald-500 to-emerald-600 px-4 py-2 text-[12px] font-semibold text-white shadow-md shadow-emerald-500/25 ring-1 ring-inset ring-emerald-600/50 transition hover:from-emerald-400 hover:to-emerald-600 hover:shadow-lg hover:shadow-emerald-500/30 active:scale-95 focus:outline-none focus:ring-2 focus:ring-emerald-400 focus:ring-offset-2 dark:focus:ring-offset-slate-900"
                          >
                            <.icon name="hero-eye" class="h-4 w-4" />
                            View
                          </button>
                        </li>
                      </ul>
                    </div>
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

  # ---------------------------------------------------------------------------
  # Stat card
  # ---------------------------------------------------------------------------

  attr :label, :string, required: true
  attr :value, :any, required: true
  attr :icon, :string, required: true
  attr :tone, :string, default: "emerald"

  defp stat_card(assigns) do
    ~H"""
    <div class="relative overflow-hidden rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 p-4 shadow-sm transition hover:shadow-md">
      <div class="flex items-center justify-between">
        <div>
          <p class="text-[12px] font-medium text-slate-500 dark:text-slate-400">{@label}</p>
          <p class="mt-1 text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">
            {format_number(@value)}
          </p>
        </div>
        <div class={["h-10 w-10 rounded-xl flex items-center justify-center", tone_classes(@tone)]}>
          <.icon name={@icon} class="h-5 w-5" />
        </div>
      </div>
    </div>
    """
  end

  defp tone_classes("emerald"), do: "bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-400"
  defp tone_classes("sky"), do: "bg-sky-50 text-sky-600 dark:bg-sky-500/10 dark:text-sky-400"
  defp tone_classes("violet"), do: "bg-violet-50 text-violet-600 dark:bg-violet-500/10 dark:text-violet-400"
  defp tone_classes("amber"), do: "bg-amber-50 text-amber-600 dark:bg-amber-500/10 dark:text-amber-400"
  defp tone_classes(_), do: "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300"

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Show/hide the uploads row, rotate the chevron, and tint the officer row
  defp toggle_reports(key) do
    JS.toggle_class("hidden", to: "#reports-#{key}")
    |> JS.toggle_class("rotate-90", to: "#chev-#{key}")
    |> JS.toggle_class("bg-emerald-50/40", to: "#row-#{key}")
  end

  # @reports is an AsyncResult (loading / failed / ok). Fall back to an empty map.
  defp reports_by_user(%Phoenix.LiveView.AsyncResult{ok?: true, result: result})
       when is_map(result),
       do: result

  defp reports_by_user(_), do: %{}

  # created_at is UTC; +1 hour shifts to Lagos time (WAT)
  defp format_dt(nil), do: "—"

  defp format_dt(%DateTime{} = dt) do
    dt |> DateTime.add(3600, :second) |> Calendar.strftime("%d %b %Y, %I:%M %p")
  end

  defp initials(nil), do: "?"

  defp initials(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
    |> case do
      "" -> "?"
      v -> v
    end
  end

  # 12345 -> "12,345"
  defp format_number(n) when is_integer(n) do
    n
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end

  defp format_number(n), do: to_string(n)

  defp count_unique(rows, key) do
    rows |> Enum.map(&Map.get(&1, key)) |> Enum.uniq() |> length()
  end
end
