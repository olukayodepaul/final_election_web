defmodule WebApiElectionWeb.Admin.SwitchDashboardLive.Components.CdrModal do
  @moduledoc "Renders the call-detail modal for a single CDR row."
  use Phoenix.Component

  alias WebApiElectionWeb.Admin.SwitchDashboardLive.Helpers

  attr :cdr, :map, required: true

  def cdr_modal(assigns) do
    ~H"""
    <div phx-click="close-cdr-modal" class="fixed inset-0 z-40 bg-slate-950/70 flex items-start justify-center overflow-y-auto py-16 px-4">
      <div onclick="event.stopPropagation()" class="w-full max-w-xl bg-white dark:bg-slate-900 rounded-2xl shadow-2xl border border-hairline dark:border-slate-800">
        <div class="flex items-center justify-between px-7 py-6 border-b border-hairline dark:border-slate-800">
          <div>
            <h3 class="text-[19px] font-semibold">Call Detail</h3>
            <p class="text-[12px] text-muted dark:text-slate-400 mt-0.5 font-mono">{@cdr.call_id}</p>
          </div>
          <button phx-click="close-cdr-modal" aria-label="Close" class="h-8 w-8 rounded-lg flex items-center justify-center text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 6l12 12M18 6L6 18" /></svg>
          </button>
        </div>

        <div class="px-7 py-6">
          <div class="flex items-center gap-2 mb-6">
            <span class={["inline-block px-2.5 py-1 rounded-md text-[12px] font-semibold", Helpers.status_badge_class(@cdr.status)]}>{@cdr.status}</span>
            <span class="text-[12px] text-muted dark:text-slate-400">{@cdr.disposition}</span>
          </div>

          <div class="grid grid-cols-2 gap-x-6 gap-y-4 text-[13px]">
            <div>
              <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-1">TIME</div>
              <div class="font-medium">{@cdr.time}</div>
            </div>
            <div>
              <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-1">DURATION</div>
              <div class="font-medium">{@cdr.dur}</div>
            </div>
            <div>
              <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-1">FROM</div>
              <div class="font-medium">{@cdr.from}</div>
            </div>
            <div>
              <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-1">TO</div>
              <div class="font-medium">{@cdr.to}</div>
            </div>
            <div>
              <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-1">CARRIER</div>
              <div class="font-medium">{@cdr.carrier}</div>
            </div>
            <div>
              <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-1">COUNTRY</div>
              <div class="font-medium">{@cdr.cc}</div>
            </div>
            <div>
              <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-1">PDD</div>
              <div class="font-medium">{@cdr.pdd}ms</div>
            </div>
            <div>
              <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-1">MOS</div>
              <div class="font-medium text-emerald-600 dark:text-emerald-400">{@cdr.mos}</div>
            </div>
            <div>
              <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-1">TRUNK</div>
              <div class="font-medium">{@cdr.trunk}</div>
            </div>
            <div>
              <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-1">SWITCH</div>
              <div class="font-medium">{@cdr.switch}</div>
            </div>
          </div>
        </div>

        <div class="flex justify-end gap-2 px-7 py-5 border-t border-hairline dark:border-slate-800">
          <button phx-click="close-cdr-modal" class="text-[13px] font-medium border border-hairline dark:border-slate-700 rounded-lg px-4 py-2 hover:bg-slate-50 dark:hover:bg-slate-800">Close</button>
        </div>
      </div>
    </div>
    """
  end
end
