defmodule WebApiElectionWeb.Admin.SwitchDashboardLive.Components.SwitchModal do
  @moduledoc "Renders the switch-detail modal (stats, Sofia gateways, verto clients)."
  use Phoenix.Component

  attr :switch_name, :string, required: true
  attr :stats, :map, required: true
  attr :gateways, :list, required: true
  attr :clients, :list, required: true

  def switch_modal(assigns) do
    ~H"""
    <div phx-click="close-switch-modal" class="fixed inset-0 z-40 bg-slate-950/70 flex items-start justify-center overflow-y-auto py-16 px-4">
      <div onclick="event.stopPropagation()" class="w-full max-w-2xl bg-white dark:bg-slate-900 rounded-2xl shadow-2xl border border-hairline dark:border-slate-800">
        <div class="flex items-center justify-between px-7 py-6 border-b border-hairline dark:border-slate-800">
          <h3 class="text-[19px] font-semibold">{@switch_name}</h3>
          <button phx-click="close-switch-modal" aria-label="Close" class="h-8 w-8 rounded-lg flex items-center justify-center text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 6l12 12M18 6L6 18" /></svg>
          </button>
        </div>

        <div class="px-7 pt-6">
          <div class="grid grid-cols-4 gap-3 mb-7">
            <div class="border border-hairline dark:border-slate-800 rounded-xl p-4">
              <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-1.5">CALLS</div>
              <div class="text-[18px] font-semibold text-brand">{@stats.calls}</div>
            </div>
            <div class="border border-hairline dark:border-slate-800 rounded-xl p-4">
              <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-1.5">CHANNELS</div>
              <div class="text-[18px] font-semibold text-brand">{@stats.channels}</div>
            </div>
            <div class="border border-hairline dark:border-slate-800 rounded-xl p-4">
              <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-1.5">VERTO</div>
              <div class="text-[18px] font-semibold text-emerald-600 dark:text-emerald-400">{@stats.verto}</div>
            </div>
            <div class="border border-hairline dark:border-slate-800 rounded-xl p-4">
              <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-1.5">UPTIME</div>
              <div class="text-[18px] font-semibold text-emerald-600 dark:text-emerald-400">{@stats.uptime}</div>
            </div>
          </div>

          <div class="text-[11px] tracking-wide font-semibold text-muted dark:text-slate-400 mb-2">SOFIA GATEWAYS</div>
          <div class="overflow-hidden border border-hairline dark:border-slate-800 rounded-xl mb-7">
            <table class="w-full text-[13px]">
              <thead>
                <tr class="text-left text-[11px] tracking-wide text-muted dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-hairline dark:border-slate-800">
                  <th class="px-4 py-2.5 font-medium">GATEWAY</th>
                  <th class="px-4 py-2.5 font-medium">STATE</th>
                  <th class="px-4 py-2.5 font-medium">STATUS</th>
                </tr>
              </thead>
              <tbody>
                <tr :for={g <- @gateways} class="border-b border-hairline dark:border-slate-800 last:border-0 hover:bg-slate-50 dark:hover:bg-slate-900">
                  <td class="px-4 py-2.5">{g.gateway}</td>
                  <td class="px-4 py-2.5 text-slate-500 dark:text-slate-400">{g.state}</td>
                  <td class="px-4 py-2.5">
                    <span class="inline-block px-2 py-0.5 rounded-md text-[11px] font-semibold bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-400">{g.status}</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="text-[11px] tracking-wide font-semibold text-muted dark:text-slate-400 mb-2">VERTO CLIENTS</div>
          <div class="overflow-hidden border border-hairline dark:border-slate-800 rounded-xl mb-7 max-h-72 overflow-y-auto">
            <table class="w-full text-[13px] whitespace-nowrap">
              <thead>
                <tr class="text-left text-[11px] tracking-wide text-muted dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-hairline dark:border-slate-800">
                  <th class="px-4 py-2.5 font-medium">USER</th>
                  <th class="px-4 py-2.5 font-medium">IP</th>
                  <th class="px-4 py-2.5 font-medium">TYPE</th>
                  <th class="px-4 py-2.5 font-medium"></th>
                </tr>
              </thead>
              <tbody>
                <tr :for={c <- @clients} class="border-b border-hairline dark:border-slate-800 last:border-0 hover:bg-slate-50 dark:hover:bg-slate-900">
                  <td class="px-4 py-2.5">{c.user}</td>
                  <td class="px-4 py-2.5 text-slate-500 dark:text-slate-400">{c.type}</td>
                  <td class="px-4 py-2.5 text-slate-500 dark:text-slate-400">verto</td>
                  <td class="px-4 py-2.5">
                    <span class="inline-block px-2 py-0.5 rounded-md text-[11px] font-semibold bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-400">ONLINE</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
