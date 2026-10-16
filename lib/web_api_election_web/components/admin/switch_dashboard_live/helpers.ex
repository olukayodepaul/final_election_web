defmodule WebApiElectionWeb.Admin.SwitchDashboardLive.Helpers do
  @moduledoc """
  Shared helper/formatting functions used by more than one page component
  in the Switch Dashboard LiveView. Kept public (`def`, not `defp`) so
  other component modules can call them, e.g.:

      alias WebApiElectionWeb.Admin.SwitchDashboardLive.Helpers

      Helpers.status_badge_class(cdr.status)
  """

  def filtered_state_results(results, filter) do
    filter = String.downcase(filter || "")

    Enum.filter(results, fn r ->
      String.contains?(String.downcase(r.state), filter)
    end)
  end

  def status_badge_class("OK"), do: "bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-400"
  def status_badge_class("BUSY"), do: "bg-amber-50 text-amber-600 dark:bg-amber-500/10 dark:text-amber-400"
  def status_badge_class("FAIL"), do: "bg-rose-50 text-rose-600 dark:bg-rose-500/10 dark:text-rose-400"
  def status_badge_class("NO ANS"), do: "bg-amber-50 text-amber-600 dark:bg-amber-500/10 dark:text-amber-400"
  def status_badge_class(_), do: "bg-slate-100 text-slate-600"

  def result_status_class("Declared"),
    do: "bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-400"

  def result_status_class(_),
    do: "bg-amber-50 text-amber-600 dark:bg-amber-500/10 dark:text-amber-400"

  def party_dot("APC"), do: "bg-sky-500"
  def party_dot("PDP"), do: "bg-emerald-500"
  def party_dot("LP"), do: "bg-rose-500"
  def party_dot("NNPP"), do: "bg-amber-500"
  def party_dot(_), do: "bg-slate-400"

  def verto_for_switch(verto, switch_name) do
    case Enum.filter(verto, &(&1.switch == switch_name)) do
      [] -> Enum.take(verto, 6)
      clients -> clients
    end
  end

  def switch_stats_for(stats, name),
    do: Map.get(stats, name, %{calls: 0, channels: 0, verto: 0, uptime: "0s"})

  def fo_status_badge(true),
    do: {"YES", "bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-400"}

  def fo_status_badge(false),
    do: {"NO", "bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400"}

  def fo_status_badge(_),
    do: {"—", "bg-slate-100 text-slate-400 dark:bg-slate-800 dark:text-slate-500"}
end
