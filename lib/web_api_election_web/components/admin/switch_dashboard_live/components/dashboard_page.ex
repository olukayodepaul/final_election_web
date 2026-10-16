defmodule WebApiElectionWeb.Admin.SwitchDashboardLive.Components.DashboardPage do
  @moduledoc """
  Renders the "Dashboard" tab: aggregate election analytics and operational
  insight views derived from the field officer dataset.
  """
  use Phoenix.Component

  attr :field_officer, :any, required: true

  def dashboard_page(assigns) do
    ~H"""
    <div>
      <h1 class="text-[26px] font-semibold mb-1">Dashboard</h1>
      <p class="text-[13px] text-muted dark:text-slate-400 mb-6">Real-time overview</p>

      <.async_result :let={officers} assign={@field_officer}>
        <:loading>
          <div class="flex flex-col items-center justify-center p-16 border border-slate-200 rounded-xl bg-slate-50/50 dark:bg-slate-900/50">
            <div class="w-8 h-8 border-3 border-brand border-t-transparent rounded-full animate-spin mb-3"></div>
            <p class="text-sm text-muted dark:text-slate-400 font-medium">Loading dashboard data...</p>
          </div>
        </:loading>

        <:failed :let={_reason}>
          <div class="p-6 text-center border border-slate-200 bg-rose-50/50 dark:bg-rose-950/20 text-rose-600 dark:text-rose-400 rounded-xl text-sm">
            Failed to load dashboard data. Please try refreshing.
          </div>
        </:failed>

        <% turnout = turnout_stats(officers) %>
        <% funnel = funnel_stats(officers) %>
        <% bvas = bvas_health(officers) %>
        <% collation = collation_stats(officers) %>
        <% anomalies = anomalies(officers) %>
        <% lgs = lg_breakdown(officers) %>

        <!-- ===== Top KPI tiles ===== -->
        <div class="grid grid-cols-5 gap-4 mb-8">
          <div class="border border-slate-200 rounded-xl p-5">
            <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-2">TOTAL VOTERS</div>
            <div class="text-2xl font-semibold text-brand tabular-nums">{turnout.total_voters}</div>
          </div>
          <div class="border border-slate-200 rounded-xl p-5">
            <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-2">PVC COLLECTED</div>
            <div class="text-2xl font-semibold text-brand tabular-nums">{turnout.total_pvc}</div>
          </div>
          <div class="border border-slate-200 rounded-xl p-5">
            <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-2">TURNOUT RATE</div>
            <div class="text-2xl font-semibold text-emerald-600 tabular-nums">{turnout.pct}%</div>
          </div>
          <div class="border border-slate-200 rounded-xl p-5">
            <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-2">FIELD OFFICERS</div>
            <div class="text-2xl font-semibold text-emerald-600 tabular-nums">{length(officers)}</div>
          </div>
          <div class={[
            "border rounded-xl p-5",
            length(anomalies) > 0 && "border-rose-200 bg-rose-50/40 dark:bg-rose-950/10",
            length(anomalies) == 0 && "border-slate-200"
          ]}>
            <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-2">ACTIVE ALERTS</div>
            <div class={["text-2xl font-semibold tabular-nums", length(anomalies) > 0 && "text-rose-600", length(anomalies) == 0 && "text-emerald-600"]}>
              {length(anomalies)}
            </div>
          </div>
        </div>

        <!-- ===== Election-day progress funnel ===== -->
        <h2 class="text-[16px] font-semibold mb-3">Election-Day Progress</h2>
        <div class="border border-slate-200 rounded-xl p-5 mb-8 space-y-4">
          <div :for={{label, count, total} <- funnel}>
            <div class="flex items-center justify-between text-[13px] mb-1.5">
              <span class="font-medium">{label}</span>
              <span class="text-muted dark:text-slate-400 tabular-nums">{count} / {total} PUs ({pct(count, total)}%)</span>
            </div>
            <div class="h-2 rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
              <div class="h-full rounded-full bg-brand" style={"width: #{pct(count, total)}%"}></div>
            </div>
          </div>
        </div>

        <div class="grid grid-cols-3 gap-6 mb-8">
          <!-- ===== BVAS health ===== -->
          <div class="border border-slate-200 rounded-xl p-5">
            <h2 class="text-[15px] font-semibold mb-4">BVAS Health</h2>
            <div class="space-y-3">
              <div>
                <div class="flex items-center justify-between text-[13px] mb-1">
                  <span>Available</span>
                  <span class="text-muted dark:text-slate-400 tabular-nums">{bvas.available} / {bvas.total} ({pct(bvas.available, bvas.total)}%)</span>
                </div>
                <div class="h-2 rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
                  <div class="h-full rounded-full bg-sky-500" style={"width: #{pct(bvas.available, bvas.total)}%"}></div>
                </div>
              </div>
              <div>
                <div class="flex items-center justify-between text-[13px] mb-1">
                  <span>Working</span>
                  <span class="text-muted dark:text-slate-400 tabular-nums">{bvas.working} / {bvas.total} ({pct(bvas.working, bvas.total)}%)</span>
                </div>
                <div class="h-2 rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
                  <div class="h-full rounded-full bg-emerald-500" style={"width: #{pct(bvas.working, bvas.total)}%"}></div>
                </div>
              </div>
            </div>
          </div>

          <!-- ===== Ward collation integrity ===== -->
          <div class="border border-slate-200 rounded-xl p-5">
            <h2 class="text-[15px] font-semibold mb-4">Ward Collation Integrity</h2>
            <dl class="space-y-2.5 text-[13px]">
              <div class="flex items-center justify-between">
                <dt class="text-muted dark:text-slate-400">Proceeded to ward</dt>
                <dd class="font-medium tabular-nums">{collation.proceeded} / {collation.total}</dd>
              </div>
              <div class="flex items-center justify-between">
                <dt class="text-muted dark:text-slate-400">PU officer at collation</dt>
                <dd class="font-medium tabular-nums">{collation.pu_officer_arrived} / {collation.total}</dd>
              </div>
              <div class="flex items-center justify-between">
                <dt class="text-muted dark:text-slate-400">INEC officer at collation</dt>
                <dd class="font-medium tabular-nums">{collation.inec_officer_arrived} / {collation.total}</dd>
              </div>
              <div class="flex items-center justify-between pt-2 mt-1 border-t border-slate-100 dark:border-slate-800">
                <dt class={collation.mismatches > 0 && "text-rose-600 font-medium" || "text-muted dark:text-slate-400"}>
                  Officer mismatches
                </dt>
                <dd class={["font-semibold tabular-nums", collation.mismatches > 0 && "text-rose-600"]}>{collation.mismatches}</dd>
              </div>
            </dl>
          </div>

          <!-- ===== Top local governments by completion ===== -->
          <div class="border border-slate-200 rounded-xl p-5">
            <h2 class="text-[15px] font-semibold mb-4">Reporting by LG</h2>
            <div class="space-y-2.5">
              <div :for={lg <- Enum.take(lgs, 5)} class="text-[13px]">
                <div class="flex items-center justify-between mb-1">
                  <span class="truncate">{lg.lg}</span>
                  <span class="text-muted dark:text-slate-400 tabular-nums shrink-0 ml-2">{lg.concluded}/{lg.total}</span>
                </div>
                <div class="h-1.5 rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
                  <div class="h-full rounded-full bg-indigo-500" style={"width: #{lg.pct}%"}></div>
                </div>
              </div>
              <div :if={lgs == []} class="text-[13px] text-muted dark:text-slate-400">No data yet</div>
            </div>
          </div>
        </div>

        <!-- ===== Active alerts / anomalies ===== -->
        <h2 class="text-[16px] font-semibold mb-3">Active Alerts</h2>
        <div class="border border-slate-200 rounded-xl overflow-hidden">
          <table :if={anomalies != []} class="w-full text-[13px] border-collapse">
            <thead>
              <tr class="text-left text-[11px] tracking-wide text-muted dark:text-slate-400 bg-slate-50 dark:bg-slate-900 border-b border-slate-200">
                <th class="px-4 py-3 font-medium">Polling Unit</th>
                <th class="px-4 py-3 font-medium">Ward</th>
                <th class="px-4 py-3 font-medium">Issue</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={a <- anomalies} class="border-b border-slate-100 last:border-0 hover:bg-rose-50/40 dark:hover:bg-rose-950/10">
                <td class="px-4 py-2.5">{a.pu_name} <span class="text-slate-400 font-mono text-[11px]">({a.pu_code})</span></td>
                <td class="px-4 py-2.5">{a.ward_name}</td>
                <td class="px-4 py-2.5 text-rose-600 font-medium">{a.issue}</td>
              </tr>
            </tbody>
          </table>
          <div :if={anomalies == []} class="p-6 text-center text-[13px] text-muted dark:text-slate-400">
            No active alerts — all reporting polling units look healthy.
          </div>
        </div>
      </.async_result>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Stat helpers
  # ---------------------------------------------------------------------------

  defp turnout_stats(officers) do
    total_voters = Enum.reduce(officers, 0, fn o, acc -> acc + (o.rgv || 0) end)
    total_pvc = Enum.reduce(officers, 0, fn o, acc -> acc + (o.pc || 0) end)
    %{total_voters: total_voters, total_pvc: total_pvc, pct: pct(total_pvc, total_voters)}
  end

  defp funnel_stats(officers) do
    total = length(officers)

    [
      {"Arrived at Polling Unit", Enum.count(officers, &(!is_nil(&1.inec_ar_time))), total},
      {"Accreditation Started", Enum.count(officers, & &1.has_accr_commence), total},
      {"Voting Started", Enum.count(officers, & &1.has_voting_commence), total},
      {"Voting Concluded", Enum.count(officers, & &1.is_conclusive), total},
      {"Result Upload to IReV", Enum.count(officers, & &1.result_upload_to_irev), total}
    ]
  end

  defp bvas_health(officers) do
    total = length(officers)

    %{
      total: total,
      available: Enum.count(officers, & &1.is_bvas_available),
      working: Enum.count(officers, & &1.is_bvas_working)
    }
  end

  defp collation_stats(officers) do
    total = length(officers)

    %{
      total: total,
      proceeded: Enum.count(officers, & &1.has_proceed_to_ward),
      pu_officer_arrived: Enum.count(officers, & &1.is_pu_officer_at_collation_center),
      inec_officer_arrived: Enum.count(officers, & &1.is_inec_officer_at_collation_center),
      mismatches: Enum.count(officers, &(&1.is_inec_officer_same_as_pu_officer == false))
    }
  end

  defp anomalies(officers) do
    Enum.flat_map(officers, fn o ->
      []
      |> maybe_add_anomaly(o, o.is_voting_cancel == true, "Voting cancelled")
      |> maybe_add_anomaly(o, o.security_present == false, "No security present")
      |> maybe_add_anomaly(o, o.is_bvas_available == true and o.is_bvas_working == false, "BVAS available but not working")
      |> maybe_add_anomaly(o, o.is_inec_officer_same_as_pu_officer == false, "Officer mismatch at collation center")
    end)
  end

  defp maybe_add_anomaly(list, _officer, false, _issue), do: list

  defp maybe_add_anomaly(list, officer, true, issue) do
    list ++ [%{pu_name: officer.pu_name, pu_code: officer.pu_code, ward_name: officer.ward_name, issue: issue}]
  end

  defp lg_breakdown(officers) do
    officers
    |> Enum.group_by(& &1.lg_name)
    |> Enum.map(fn {lg, list} ->
      total = length(list)
      concluded = Enum.count(list, & &1.is_conclusive)
      %{lg: lg, total: total, concluded: concluded, pct: pct(concluded, total)}
    end)
    |> Enum.sort_by(& &1.total, :desc)
  end

  defp pct(_count, 0), do: 0
  defp pct(count, total), do: round(count / total * 100)
end
