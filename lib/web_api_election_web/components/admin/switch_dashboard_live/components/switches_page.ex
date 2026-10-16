defmodule WebApiElectionWeb.Admin.SwitchDashboardLive.Components.PartiesPage do
  @moduledoc "Renders the 'Political Parties' tab: registered party cards."
  use Phoenix.Component

  attr :parties, :list, required: true

  def parties_page(assigns) do
    ~H"""
    <div>
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-[26px] font-semibold">Political Parties</h1>
      </div>

      <div class="grid grid-cols-4 gap-5">
        <div
          :for={p <- @parties}
          class="bg-slate-50 dark:bg-slate-900/40 border border-slate-200 dark:border-slate-800 rounded-xl p-5 hover:shadow-sm transition-shadow"
        >
          <div class="flex items-center gap-3 mb-4">
            <img
              :if={p[:logo]}
              src={p.logo}
              alt={"#{p.name} logo"}
              class="h-12 w-12 rounded-lg object-cover border border-slate-200 dark:border-slate-700 bg-white shrink-0"
            />
            <div
              :if={!p[:logo]}
              class="h-12 w-12 rounded-lg flex items-center justify-center bg-slate-200 dark:bg-slate-800 text-slate-600 dark:text-slate-300 font-semibold text-[13px] tracking-tight shrink-0"
            >
              {p.acronym}
            </div>
            <div class="min-w-0">
              <div class="font-semibold text-[14px] text-slate-800 dark:text-slate-100 truncate">{p.name}</div>
              <div class="text-[12px] text-slate-500 dark:text-slate-400">{p.acronym}</div>
            </div>
          </div>

          <div class="border-t border-slate-200 dark:border-slate-800 pt-3">
            <div class="text-[10px] font-medium tracking-wide text-slate-400 dark:text-slate-500 mb-1">HEAD OFFICE</div>
            <div class="text-[13px] leading-snug text-slate-600 dark:text-slate-300">{p.head_office}</div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
