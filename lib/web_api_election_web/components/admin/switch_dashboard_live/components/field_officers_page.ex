defmodule WebApiElectionWeb.Admin.SwitchDashboardLive.Components.FieldOfficersPage do
  @moduledoc """
  Renders the 'Field Officers' tab: live status table sourced from
  `SupervisorMonitorQuery` in the parent LiveView's `mount/3` and
  patched via `handle_info/2` PubSub messages.
  """
  use Phoenix.Component

  alias WebApiElectionWeb.Admin.SwitchDashboardLive.Helpers

  attr :field_officer_states, :list, required: true

  def field_officers_page(assigns) do
    ~H"""
    <div>
      <div class="flex items-center justify-between mb-1">
        <h1 class="text-[26px] font-semibold">Field Officer Reports</h1>
        <span class="inline-flex items-center gap-1.5 text-[12px] font-semibold px-3 py-1.5 rounded-full bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-400">
          <span class="h-1.5 w-1.5 rounded-full bg-emerald-500"></span> Live
        </span>
      </div>
      <p class="text-[13px] text-muted dark:text-slate-400 mb-6">Real-time status from your assigned field officers</p>

      <div class="grid grid-cols-4 gap-4 mb-8">
        <div class="border border-hairline dark:border-slate-800 rounded-xl p-5">
          <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-2">TOTAL OFFICERS</div>
          <div class="text-2xl font-semibold text-brand">{length(@field_officer_states)}</div>
        </div>
        <div class="border border-hairline dark:border-slate-800 rounded-xl p-5">
          <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-2">VOTING STARTED</div>
          <div class="text-2xl font-semibold text-emerald-600">
            {Enum.count(@field_officer_states, & &1.has_voting_commence)}
          </div>
        </div>
        <div class="border border-hairline dark:border-slate-800 rounded-xl p-5">
          <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-2">VOTING CANCELLED</div>
          <div class="text-2xl font-semibold text-rose-600">
            {Enum.count(@field_officer_states, & &1.is_voting_cancel)}
          </div>
        </div>
        <div class="border border-hairline dark:border-slate-800 rounded-xl p-5">
          <div class="text-[11px] tracking-wide text-muted dark:text-slate-400 mb-2">AGENTS CLEARED</div>
          <div class="text-2xl font-semibold text-brand">
            {Enum.count(@field_officer_states, & &1.did_inec_clear_agent)}
          </div>
        </div>
      </div>

      <div class="overflow-x-auto border border-hairline dark:border-slate-800 rounded-xl">
        <table class="w-full text-[13px] whitespace-nowrap">
          <thead>
            <tr class="text-left text-[11px] tracking-wide text-muted dark:text-slate-400 border-b border-hairline dark:border-slate-800">
              <th class="px-4 py-3 font-medium">STATE</th>
              <th class="px-4 py-3 font-medium">LGA</th>
              <th class="px-4 py-3 font-medium">WARD</th>
              <th class="px-4 py-3 font-medium">SECURITY</th>
              <th class="px-4 py-3 font-medium">BVAS AVAIL.</th>
              <th class="px-4 py-3 font-medium">BVAS WORKING</th>
              <th class="px-4 py-3 font-medium">ACCR. STARTED</th>
              <th class="px-4 py-3 font-medium">VOTING STARTED</th>
              <th class="px-4 py-3 font-medium">VOTING CANCELLED</th>
              <th class="px-4 py-3 font-medium">AGENT PRESENT</th>
              <th class="px-4 py-3 font-medium">AGENT CLEARED</th>
              <th class="px-4 py-3 font-medium">LAST UPDATE</th>
            </tr>
          </thead>
          <tbody id="field-officer-rows">
            <tr
              :for={row <- @field_officer_states}
              id={"fo-row-#{row.user_id}"}
              class="border-b border-hairline dark:border-slate-800 last:border-0 hover:bg-slate-50 dark:hover:bg-slate-900"
            >
              <td class="px-4 py-3">{row.state_name}</td>
              <td class="px-4 py-3">{row.lg_name}</td>
              <td class="px-4 py-3">{row.ward_name}</td>
              <td class="px-4 py-3"><.fo_badge value={row.security_present} /></td>
              <td class="px-4 py-3"><.fo_badge value={row.is_bvas_available} /></td>
              <td class="px-4 py-3"><.fo_badge value={row.is_bvas_working} /></td>
              <td class="px-4 py-3"><.fo_badge value={row.has_accr_commence} /></td>
              <td class="px-4 py-3"><.fo_badge value={row.has_voting_commence} /></td>
              <td class="px-4 py-3"><.fo_badge value={row.is_voting_cancel} /></td>
              <td class="px-4 py-3"><.fo_badge value={row.is_agent_at_polling_unit} /></td>
              <td class="px-4 py-3"><.fo_badge value={row.did_inec_clear_agent} /></td>
              <td class="px-4 py-3 text-slate-500 dark:text-slate-400">
                {row.inec_ar_time && Calendar.strftime(row.inec_ar_time, "%H:%M:%S")}
              </td>
            </tr>
            <tr :if={@field_officer_states == []}>
              <td colspan="12" class="px-4 py-6 text-center text-slate-400 text-[13px]">No field officers assigned yet</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  # Small local sub-component: only used within this page, so it lives
  # here rather than in its own file. Still callable as <.fo_badge .../>
  # because it's defined in the same module.
  attr :value, :any, required: true

  defp fo_badge(assigns) do
    {label, class} = Helpers.fo_status_badge(assigns.value)
    assigns = assign(assigns, label: label, class: class)

    ~H"""
    <span class={["inline-block px-2 py-0.5 rounded-md text-[11px] font-semibold", @class]}>{@label}</span>
    """
  end
end
