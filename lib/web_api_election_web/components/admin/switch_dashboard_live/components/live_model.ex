defmodule WebApiElectionWeb.Admin.SwitchDashboardLive.Components.LiveModal do
  @moduledoc """
  Components for the field-officer monitoring modal and the dashboard's
  "Live Monitoring" stats header.
  """
  use WebApiElectionWeb, :html
  alias Phoenix.LiveView.JS

  attr :if, :boolean, default: true
  attr :officer, :map, required: true
  attr :messages, :list, default: []
  attr :notifications, :map, default: %{}
  attr :presiding_officer_report, :any, default: nil
  attr :loading_presiding_officer, :boolean, default: false
  attr :pu_security_report, :any, default: nil
  attr :loading_pu_security, :boolean, default: false
  attr :ward_security_report, :any, default: nil
  attr :loading_ward_security, :boolean, default: false
  attr :party_agent_report, :any, default: nil
  attr :loading_party_agent, :boolean, default: false

  @categories [
    {:incident, "INEC Presiding Officer", "hero-user"},
    {:security, "Ward Collation Center", "hero-building-office-2"},
    {:polling_unit, "Party Agent", "hero-users"},
    {:ward, "PU Security", "hero-shield-check"},
    {:emergency, "Emergency Report", "hero-bell-alert"}
  ]

  # ---------------------------------------------------------------------------
  # Per-panel labels. Any key not listed falls back to `fallback_humanize/1`.
  # ---------------------------------------------------------------------------

  @presiding_labels %{
    "arrivalTime" => "Arrival Time",
    "hasAccredCommence" => "Accreditation Commenced",
    "hasVolingCommence" => "Voting Commenced",
    "isBallotBoxEmptyAndSecure_leading" => "Ballot Box Empty & Secure (Leading Agent)",
    "isBallotBoxEmptyAndSecure_trail" => "Ballot Box Empty & Secure (Trailing Agent)",
    "isBallotPaperAvail_leading" => "Ballot Paper Available (Leading Agent)",
    "isBallotPaperAvail_trail" => "Ballot Paper Available (Trailing Agent)",
    "isBallotShownEmptyToAgent_leading" => "Ballot Shown Empty to Agent (Leading Agent)",
    "isBallotShownEmptyToAgent_trail" => "Ballot Shown Empty to Agent (Trailing Agent)",
    "isBvbDeviceGoodCond" => "BVAS Device in Good Condition",
    "isBvnMachineAvail" => "BVAS Machine Available",
    "isEc60eAvail_leading" => "EC60E Form Available (Leading Agent)",
    "isEc60eAvail_trail" => "EC60E Form Available (Trailing Agent)",
    "isEc8ResultSheetPresent_leading" => "EC8 Result Sheet Present (Leading Agent)",
    "isEc8ResultSheetPresent_trail" => "EC8 Result Sheet Present (Trailing Agent)",
    "isLat" => "Latitude",
    "isLng" => "Longitude",
    "isSecurityPersonnelPresent" => "Security Personnel Present",
    "isVotersVerifyWithBvas" => "Voters Verified with BVAS",
    "numberOfInecOfficial" => "Number of INEC Officials",
    "isInecOfficialWearingTag" => "INEC Officials Wearing ID Tags",
    "accreditationMethod" => "Accreditation Method",
    "electionOutcome" => "Election Outcome",
    # per-election materials (electionMaterials)
    "ec8aPresent" => "EC8A Result Sheet Present",
    "ec60ePresent" => "EC60E Form Present",
    "ballotPapersPresent" => "Ballot Papers Available",
    "boxSecure" => "Ballot Box Empty & Secure",
    "boxShownEmpty" => "Ballot Box Shown Empty to Agents",
    # older flat keys
    "isEc8ResultSheetPresentLeading" => "EC8 Result Sheet Present",
    "isEc60eAvailLeading" => "EC60E Form Available",
    "isBallotPaperAvailLeading" => "Ballot Paper Available",
    "isEc8ResultSheetPresentTrail" => "EC8 Result Sheet Present",
    "isEc60eAvailTrail" => "EC60E Form Available",
    "isBallotPaperAvailTrail" => "Ballot Paper Available",
    "isBallotBoxEmptyAndSecureTrail" => "Ballot Box Empty & Secure",
    "isBallotShownEmptyToAgentTrail" => "Ballot Shown Empty to Agent",
    "isRepEc8ResultSheetPresentTrail" => "EC8 Result Sheet Present",
    "isRepEc60eAvailTrail" => "EC60E Form Available",
    "isRepBallotPaperAvailTrail" => "Ballot Paper Available",
    "isRepBallotBoxEmptyAndSecureTrail" => "Ballot Box Empty & Secure",
    "isRepBallotShownEmptyToAgentTrail" => "Ballot Shown Empty to Agent"
  }

  @pu_security_labels %{
    "securityPresence" => "Security Presence",
    "isDssPresent" => "DSS Present",
    "isNpfPresent" => "NPF (Police) Present",
    "isArmyPresent" => "Army Present",
    "isNscdcPresent" => "NSCDC Present",
    "isBallotsSnached" => "Ballots Snatched",
    "isPersonnelArmed" => "Personnel Armed",
    "isElectionCanceled" => "Election Cancelled",
    "isMaintainingOrder" => "Maintaining Order",
    "securityPersonnelCount" => "Security Personnel Count",
    "isSecurityPersonPresent" => "Security Personnel Present",
    "isVotingDisruptedByViolence" => "Voting Disrupted by Violence",
    "isObserversMainainingDistance" => "Observers Maintaining Distance",
    "isPersonnelUniformedCompliant" => "Personnel Uniform Compliant",
    "isUnauthorizedInfluenceObserved" => "Unauthorized Influence Observed"
  }

  @ward_security_labels %{
    "collationStatus" => "Collation Status",
    "partyAgentMovement" => "Party Agent Movement",
    "isPartyAgentsArriveAtCollationCenter" => "Party Agents Arrived at Collation Centre",
    "isPartyAgentsProceedToWard" => "Party Agents Proceeded to Ward",
    "isAgentsDeniedAccess" => "Agents Denied Access",
    "materialsGuarded" => "Materials Guarded",
    "securityPersonnelPresent" => "Security Personnel Present",
    "presidingOfficerIdentified" => "Presiding Officer Identified",
    "isEc8bCompleted" => "EC8B Completed",
    "isEc8bCopiesIssued" => "EC8B Copies Issued",
    "isBriberyAttemptDetected" => "Bribery Attempt Detected",
    "isPersonnelInfluencingOfficer" => "Personnel Influencing Officer"
  }

  @party_agent_labels %{
    "agentClearance" => "INEC Clearance",
    "agentArrivalTime" => "Arrival Time",
    "clearedTime" => "Cleared Time",
    "isLat" => "Latitude",
    "isLng" => "Longitude",
    "isAtAssignedUnit" => "At Assigned Unit",
    "isCoordinatorPresent" => "Coordinator Present",
    "isAgentVerifiedByInec" => "Agent Verified by INEC",
    "isArrivalTimeRecorded" => "Arrival Time Recorded",
    "isCoordinatorBriefingReceived" => "Coordinator Briefing Received",
    "isWardCollationChannelEstablished" => "Ward Collation Channel Established"
  }

  @labels %{
    presiding: @presiding_labels,
    pu_security: @pu_security_labels,
    ward_security: @ward_security_labels,
    party_agent: @party_agent_labels
  }

  @agency_order ~w(dss npf army nscdc)

  @agency_labels %{
    "dss" => "DSS",
    "npf" => "NPF (Police)",
    "army" => "Army",
    "nscdc" => "NSCDC"
  }

  def live_modal(assigns) do
    assigns = assign(assigns, :categories, @categories)

    ~H"""
    <div
      :if={@if}
      id="live-monitor-modal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/60 backdrop-blur-sm p-4"
      phx-window-keydown={close_modal_js()}
      phx-key="escape"
    >
      <!-- Backdrop click to dismiss. Note: this only closes the modal - it
           intentionally does NOT touch window.phoneService, so an active
           call keeps running (floating call widget) even after the modal
           closes. -->
      <div class="fixed inset-0" phx-click={close_modal_js()}></div>

      <!-- Modal Container -->
      <div class="relative z-10 w-full max-w-5xl h-[90vh] flex flex-col rounded-2xl bg-white dark:bg-slate-900 shadow-2xl border border-slate-200 dark:border-slate-700 overflow-hidden">
        <!-- Header: officer info on the LEFT, actions on the RIGHT, both vertically centered -->
        <div class="flex items-center justify-between gap-4 shrink-0 px-6 py-4 border-b border-slate-200 dark:border-slate-800 bg-gradient-to-r from-slate-50 via-white to-white dark:from-slate-800/60 dark:via-slate-900 dark:to-slate-900">
          <!-- LEFT -->
          <div class="flex items-center gap-4 min-w-0">
            <div class="relative shrink-0">
              <div class="h-12 w-12 rounded-2xl bg-gradient-to-br from-indigo-500 to-violet-600 text-white flex items-center justify-center text-base font-semibold shadow-md shadow-indigo-500/20">
                {initials(@officer.field_officer_name)}
              </div>
              <span class="absolute -bottom-0.5 -right-0.5 h-3.5 w-3.5 rounded-full bg-emerald-500 border-2 border-white dark:border-slate-900"></span>
            </div>

            <div class="min-w-0">
              <h3 class="truncate text-lg font-semibold leading-tight text-slate-900 dark:text-slate-100">
                {@officer.field_officer_name}
              </h3>
              <p class="mt-1 flex flex-wrap items-center gap-1.5 text-xs font-medium text-slate-600 dark:text-slate-300">
                <span>{@officer.state_name}</span>
                <span class="rounded bg-slate-100 px-1 py-0.5 text-[10px] font-semibold text-slate-500 dark:bg-slate-800 dark:text-slate-400">{@officer.state_code}</span>

                <span class="text-slate-300 dark:text-slate-600">/</span>

                <span>{@officer.lg_name}</span>
                <span class="rounded bg-slate-100 px-1 py-0.5 text-[10px] font-semibold text-slate-500 dark:bg-slate-800 dark:text-slate-400">{@officer.lg_code}</span>

                <span class="text-slate-300 dark:text-slate-600">/</span>

                <span>{@officer.ward_name}</span>
                <span class="rounded bg-slate-100 px-1 py-0.5 text-[10px] font-semibold text-slate-500 dark:bg-slate-800 dark:text-slate-400">{@officer.ward_code}</span>

                <span class="text-slate-300 dark:text-slate-600">/</span>

                <span class="font-semibold text-slate-900 dark:text-slate-100">{@officer.pu_name}</span>
                <span class="rounded bg-indigo-50 px-1 py-0.5 text-[10px] font-bold text-indigo-600 dark:bg-indigo-950/50 dark:text-indigo-400">{@officer.pu_code}</span>
              </p>
            </div>
          </div>

          <!-- RIGHT -->
          <div class="flex items-center gap-2 shrink-0">
            <div class="hidden sm:flex items-center gap-1.5 h-9 rounded-full border border-emerald-200 bg-emerald-50 px-3 text-[12px] font-medium text-emerald-700 dark:border-emerald-500/20 dark:bg-emerald-500/10 dark:text-emerald-300">
              <span class="relative flex h-2 w-2">
                <span class="absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75 animate-ping"></span>
                <span class="relative inline-flex h-2 w-2 rounded-full bg-emerald-500"></span>
              </span>
              Live
            </div>

            <!-- Call button: dials this officer's SIP extension, which is
                 their user_id. Closing this modal does NOT hang up the call -
                 the floating call widget (#phone-widget, root layout)
                 persists independently. -->
            <button
              type="button"
              onclick={sip_call_js(@officer)}
              class="inline-flex h-9 items-center gap-2 rounded-full bg-emerald-600 px-4 text-[13px] font-medium text-white shadow-sm hover:bg-emerald-700 active:scale-95 transition"
              title={"Call #{officer_display_name(@officer)}"}
            >
              <.icon name="hero-phone" class="h-4 w-4 pointer-events-none" />
              <span class="hidden sm:inline">Call</span>
            </button>

            <button
              type="button"
              phx-click={close_modal_js()}
              aria-label="Close"
              class="flex h-9 w-9 items-center justify-center rounded-full border border-slate-200 text-slate-400 hover:bg-slate-100 hover:text-slate-600 dark:border-slate-700 dark:hover:bg-slate-800 dark:hover:text-slate-200 transition-colors"
            >
              <.icon name="hero-x-mark" class="h-5 w-5" />
            </button>
          </div>
        </div>

        <!-- Two-column grid: notifications (LEFT) + chat (RIGHT) -->
        <div class="flex-1 min-h-0 grid grid-cols-1 md:grid-cols-2 gap-4 px-6 py-4 overflow-hidden bg-slate-50/50 dark:bg-slate-950/20">
          <!-- Left: Notifications — header + analytics + dropdown rows -->
          <div class="flex flex-col min-h-0 rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 shadow-sm overflow-hidden">
            <!-- Panel header -->
            <div class="px-4 py-4 bg-white dark:bg-slate-900 border-b border-slate-200 dark:border-slate-800">
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="relative h-10 w-10 rounded-xl bg-gradient-to-br from-slate-100 to-slate-200 dark:from-slate-800 dark:to-slate-800/50 border border-slate-200 dark:border-slate-700 flex items-center justify-center shrink-0">
                    <.icon name="hero-bell" class="h-5 w-5 text-slate-600 dark:text-slate-300" />
                    <span
                      :if={Enum.reduce(@categories, 0, fn {key, _label, _icon}, acc -> acc + length(Map.get(@notifications, key, [])) end) > 0}
                      class="absolute -top-1 -right-1 h-4 w-4 rounded-full bg-rose-500 border-2 border-white dark:border-slate-900"
                    >
                    </span>
                  </div>
                  <div>
                    <h4 class="text-base font-semibold text-slate-900 dark:text-slate-100 leading-tight">
                      Notifications
                    </h4>
                    <p class="text-xs text-muted dark:text-slate-400 mt-0.5">
                      <% incident_count = length(Map.get(@notifications, :incident, [])) %>
                      {if incident_count > 0,
                        do: "#{incident_count} needing attention",
                        else: "All clear right now"}
                    </p>
                  </div>
                </div>

                <div class="flex items-center gap-1.5 rounded-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 px-2.5 py-1">
                  <span class="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                  <span class="text-[11px] font-medium text-slate-500 dark:text-slate-400">Live</span>
                </div>
              </div>
            </div>

            <div class="flex-1 min-h-0 overflow-y-auto p-4 space-y-5">
              <!-- Compact analytics row -->
              <div class="grid grid-cols-2 gap-3">
                <div class="relative rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50/60 dark:bg-slate-800/30 p-4">
                  <button
                    type="button"
                    class="absolute top-3 right-3 text-slate-300 dark:text-slate-600 hover:text-slate-400 dark:hover:text-slate-500"
                  >
                    <.icon name="hero-information-circle" class="h-4 w-4" />
                  </button>
                  <div class="flex items-center gap-3">
                    <div class="h-9 w-9 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 flex items-center justify-center shrink-0">
                      <.icon name="hero-exclamation-triangle" class="h-4 w-4 text-slate-500 dark:text-slate-400" />
                    </div>
                    <div>
                      <span class="block text-[11px] font-medium tracking-wide uppercase text-slate-500 dark:text-slate-400">
                        Total Incidents
                      </span>
                      <div class="text-2xl font-semibold tabular-nums text-slate-900 dark:text-slate-100 mt-0.5">
                        {length(Map.get(@notifications, :incident, []))}
                      </div>
                    </div>
                  </div>
                </div>

                <div class="relative rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50/60 dark:bg-slate-800/30 p-4">
                  <button
                    type="button"
                    class="absolute top-3 right-3 text-slate-300 dark:text-slate-600 hover:text-slate-400 dark:hover:text-slate-500"
                  >
                    <.icon name="hero-information-circle" class="h-4 w-4" />
                  </button>
                  <div class="flex items-center gap-3">
                    <div class="h-9 w-9 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 flex items-center justify-center shrink-0">
                      <.icon name="hero-bell-alert" class="h-4 w-4 text-slate-500 dark:text-slate-400" />
                    </div>
                    <div>
                      <span class="block text-[11px] font-medium tracking-wide uppercase text-slate-500 dark:text-slate-400">
                        Total Alerts
                      </span>
                      <div class="text-2xl font-semibold tabular-nums text-slate-900 dark:text-slate-100 mt-0.5">
                        {Enum.reduce(@categories, 0, fn {key, _label, _icon}, acc ->
                          acc + length(Map.get(@notifications, key, []))
                        end)}
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Category dropdown rows -->
              <div class="space-y-2">
                <div :for={{key, label, icon} <- @categories} id={"notif-group-#{key}"}>
                  <button
                    type="button"
                    phx-click={
                      cond do
                        key == :incident ->
                          JS.toggle(to: "#notif-panel-#{key}")
                          |> JS.toggle_class("rotate-180", to: "#notif-chevron-#{key}")
                          |> JS.push("fetch-presiding-officer", value: %{user_id: Map.get(@officer, :user_id)})

                        key == :ward ->
                          JS.toggle(to: "#notif-panel-#{key}")
                          |> JS.toggle_class("rotate-180", to: "#notif-chevron-#{key}")
                          |> JS.push("fetch-pu-security", value: %{user_id: Map.get(@officer, :user_id)})

                        key == :security ->
                          JS.toggle(to: "#notif-panel-#{key}")
                          |> JS.toggle_class("rotate-180", to: "#notif-chevron-#{key}")
                          |> JS.push("fetch-ward-security", value: %{user_id: Map.get(@officer, :user_id)})

                        key == :polling_unit ->
                          JS.toggle(to: "#notif-panel-#{key}")
                          |> JS.toggle_class("rotate-180", to: "#notif-chevron-#{key}")
                          |> JS.push("fetch-party-agent", value: %{user_id: Map.get(@officer, :user_id)})

                        true ->
                          JS.toggle(to: "#notif-panel-#{key}")
                          |> JS.toggle_class("rotate-180", to: "#notif-chevron-#{key}")
                      end
                    }
                    class="group w-full flex items-center justify-between rounded-lg border border-slate-200 dark:border-slate-700 px-3.5 py-2.5 text-left hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors"
                  >
                    <span class="flex items-center gap-2">
                      <.icon name={icon} class="h-4 w-4 text-slate-400" />
                      <span class="text-sm text-slate-700 dark:text-slate-200">{label}</span>
                    </span>
                    <span class="flex items-center gap-2">
                      <span
                        :if={(items = Map.get(@notifications, key, [])) != []}
                        class="inline-flex items-center justify-center h-5 min-w-5 px-1.5 rounded-full bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 text-[10px] font-semibold"
                      >
                        {length(items)}
                      </span>

                      <.icon
                        :if={key in [:incident, :ward, :security, :polling_unit]}
                        name="hero-arrow-path"
                        class="hidden h-4 w-4 text-slate-400 animate-spin group-[.phx-click-loading]:block"
                      />

                      <.icon
                        id={"notif-chevron-#{key}"}
                        name="hero-chevron-down"
                        class={[
                          "h-4 w-4 text-slate-400 transition-transform",
                          key in [:incident, :ward, :security, :polling_unit] && "group-[.phx-click-loading]:hidden"
                        ]}
                      />
                    </span>
                  </button>

                  <div id={"notif-panel-#{key}"} class="hidden mt-1 rounded-lg border border-slate-200 dark:border-slate-800 px-3 py-2 space-y-2">
                    <!-- Presiding Officer dynamic DB content panel -->
                    <div :if={key == :incident} class="text-xs">
                      <.report_state loading={@loading_presiding_officer} empty={is_nil(@presiding_officer_report)} />
                      <.presiding_panel :if={!@loading_presiding_officer && @presiding_officer_report} report={@presiding_officer_report} />
                    </div>

                    <!-- PU Security Checklist dynamic DB content panel -->
                    <div :if={key == :ward} class="text-xs">
                      <.report_state loading={@loading_pu_security} empty={is_nil(@pu_security_report)} />
                      <.pu_security_panel :if={!@loading_pu_security && @pu_security_report} report={@pu_security_report} />
                    </div>

                    <!-- Ward Collation dynamic DB content panel -->
                    <div :if={key == :security} class="text-xs">
                      <div :if={@loading_ward_security} class="flex items-center justify-start gap-2 py-4 text-slate-500 dark:text-slate-400">
                        <.icon name="hero-arrow-path" class="h-4 w-4 animate-spin text-indigo-500" />
                        <span class="font-medium">Fetching report details...</span>
                      </div>

                      <div :if={!@loading_ward_security && is_nil(@ward_security_report)} class="flex flex-col items-start justify-center rounded-xl border border-dashed border-slate-200 dark:border-slate-800 px-3 py-4 text-left">
                        <.icon name="hero-document-magnifying-glass" class="h-8 w-8 text-slate-400 dark:text-slate-600 mb-1" />
                        <p class="font-medium text-slate-500 dark:text-slate-400">No report recorded for this officer</p>
                      </div>

                      <.ward_collation_panel :if={!@loading_ward_security && @ward_security_report} report={@ward_security_report} />
                    </div>

                    <!-- Party Agent dynamic DB content panel -->
                    <div :if={key == :polling_unit} class="text-xs">
                      <.report_state loading={@loading_party_agent} empty={is_nil(@party_agent_report)} />
                      <.party_agent_panel :if={!@loading_party_agent && @party_agent_report} report={@party_agent_report} />
                    </div>

                    <!-- Default notification rendering for non-dynamic items -->
                    <div :if={key not in [:incident, :ward, :security, :polling_unit]}>
                      <div
                        :if={Map.get(@notifications, key, []) == []}
                        class="text-xs text-muted dark:text-slate-500"
                      >
                        No {String.downcase(label)} notifications.
                      </div>
                      <div :for={item <- Map.get(@notifications, key, [])} class="text-xs">
                        <div class="flex items-center justify-between">
                          <span class="font-semibold text-slate-700 dark:text-slate-200">{item[:title]}</span>
                          <span class="text-[10px] text-muted dark:text-slate-500">{item[:time]}</span>
                        </div>
                        <p :if={item[:body]} class="text-muted dark:text-slate-400 mt-0.5">{item[:body]}</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Right: Chat (WhatsApp-style) -->
          <div class="flex flex-col min-h-0 rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 shadow-sm overflow-hidden">
            <!-- Chat header -->
            <div class="flex items-center justify-between px-4 py-3 bg-white dark:bg-slate-900 border-b border-slate-200 dark:border-slate-800">
              <div class="flex items-center gap-3">
                <div class="h-10 w-10 rounded-full bg-slate-800 flex items-center justify-center overflow-hidden shrink-0">
                  <img
                    :if={Map.get(@officer, :avatar_url)}
                    src={Map.get(@officer, :avatar_url)}
                    class="h-full w-full object-cover"
                  />
                  <.icon :if={!Map.get(@officer, :avatar_url)} name="hero-user" class="h-5 w-5 text-slate-400" />
                </div>
                <div class="leading-tight">
                  <div class="text-sm font-semibold text-slate-800 dark:text-slate-100">
                    {officer_display_name(@officer)}
                  </div>
                  <div class="text-[11px] text-slate-400 dark:text-slate-500">Field officer chat</div>
                </div>
              </div>
            </div>

            <!-- Message area -->
            <div
              id="live-chat-messages"
              phx-hook="ChatScroll"
              class="flex-1 min-h-0 overflow-y-auto px-4 py-3 space-y-2 bg-[#e9e3d8] dark:bg-slate-950/40"
            >
              <div :if={@messages == []} class="text-xs text-muted dark:text-slate-500 text-center pt-8">
                No messages yet.
              </div>

              <div
                :for={msg <- @messages}
                class={[
                  "max-w-[75%] rounded-lg px-3 py-1.5 text-sm shadow-sm",
                  msg[:from] == :admin && "ml-auto bg-[#d9fdd3] dark:bg-emerald-800 text-slate-900 dark:text-slate-50",
                  msg[:from] != :admin && "mr-auto bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100"
                ]}
              >
                <img :if={msg[:type] == "IMAGE"} src={msg[:body]} class="max-w-full rounded-lg max-h-64 object-cover" />

                <video :if={msg[:type] == "VIDEO"} controls class="max-w-full rounded-lg max-h-64">
                  <source src={msg[:body]} />
                </video>

                <audio :if={msg[:type] == "AUDIO"} controls preload="none" class="w-60 max-w-full">
                  <source src={msg[:body]} type="audio/mp4" />
                </audio>

                <p :if={msg[:type] not in ["IMAGE", "VIDEO", "AUDIO"]}>{msg[:body]}</p>

                <p class="flex items-center justify-end gap-1 text-[10px] mt-0.5 text-slate-500 dark:text-slate-400">
                  {msg[:time]}
                  <.icon :if={msg[:from] == :admin} name="hero-check" class="h-3 w-3 text-blue-500" />
                </p>
              </div>
            </div>

            <!-- Input row: attach / emoji / message / send -->
            <form phx-submit="send-live-message" class="flex items-center gap-3 px-3 py-2 bg-white dark:bg-slate-900 border-t border-slate-200 dark:border-slate-800">
              <button type="button" phx-click="attach-file" title="Attach" class="text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200">
                <.icon name="hero-paper-clip" class="h-5 w-5" />
              </button>
              <button type="button" phx-click="open-emoji-picker" title="Emoji" class="text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200">
                <.icon name="hero-face-smile" class="h-5 w-5" />
              </button>
              <input
                type="text"
                name="body"
                placeholder="Type a message"
                autocomplete="off"
                class="flex-1 rounded-full border-none bg-slate-100 dark:bg-slate-800 px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
              />
              <button
                type="submit"
                class="h-9 w-9 shrink-0 flex items-center justify-center rounded-full bg-emerald-600 text-white hover:bg-emerald-700 transition-colors"
                title="Send"
              >
                <.icon name="hero-paper-airplane" class="h-4 w-4" />
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @stat_cards [
    {:total_voters, "Total Voters", "hero-users", :slate},
    {:total_pvc_collected, "Total PVC Collected", "hero-identification", :slate},
    {:field_officers, "Field Officers", "hero-user-group", :emerald},
    {:gateways, "Gateways", "hero-signal", :emerald},
    {:polling_units, "Polling Units", "hero-building-library", :emerald}
  ]

  @doc """
  Header + 5-column stat grid for the "Live Monitoring" dashboard page.
  """
  attr :stats, :map, default: %{}

  def live_monitoring_stats(assigns) do
    assigns = assign(assigns, :stat_cards, @stat_cards)

    ~H"""
    <div>
      <h1 class="text-3xl font-bold tracking-tight text-slate-900 dark:text-slate-100 mb-6">
        Live Monitoring
      </h1>

      <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4">
        <div
          :for={{key, label, icon, accent} <- @stat_cards}
          class="group rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 p-6 hover:shadow-md hover:border-slate-300 dark:hover:border-slate-700 transition-all"
        >
          <div class="flex items-center justify-between mb-4">
            <span class="text-xs font-semibold tracking-wide uppercase text-muted dark:text-slate-400">
              {label}
            </span>
            <.icon
              name={icon}
              class={[
                "h-5 w-5",
                accent == :emerald && "text-emerald-600 dark:text-emerald-500",
                accent == :slate && "text-slate-400 dark:text-slate-500"
              ]}
            />
          </div>
          <div class={[
            "text-4xl font-extrabold tabular-nums tracking-tight",
            accent == :emerald && "text-emerald-700 dark:text-emerald-400",
            accent == :slate && "text-slate-900 dark:text-slate-100"
          ]}>
            {Map.get(@stats, key, 0)}
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :value, :any, default: nil

  def bool_value(assigns) do
    ~H"""
    <span :if={@value == true} class="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2 py-0.5 text-[11px] font-medium text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-800/40">
      <.icon name="hero-check-circle" class="h-3.5 w-3.5 text-emerald-500" /> Yes
    </span>
    <span :if={@value == false} class="inline-flex items-center gap-1 rounded-full bg-rose-50 px-2 py-0.5 text-[11px] font-medium text-rose-700 dark:bg-rose-950/50 dark:text-rose-400 border border-rose-200 dark:border-rose-800/40">
      <.icon name="hero-x-circle" class="h-3.5 w-3.5 text-rose-500" /> No
    </span>
    <span :if={@value not in [true, false]} class="font-medium text-slate-800 dark:text-slate-200">
      {display_value(@value)}
    </span>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, default: nil

  def bool_row(assigns) do
    ~H"""
    <div class="flex items-center justify-between py-1.5">
      <span class="text-slate-500 dark:text-slate-400">{@label}</span>
      <.bool_value value={@value} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Hides the modal in the browser right away, then tells the server to drop it.
  # Without the hide, the close waits behind whatever the LiveView process is busy with.
  defp close_modal_js do
    JS.hide(to: "#live-monitor-modal")
    |> JS.push("close-live-modal")
  end

  # Officer display name used by the call button and chat header.
  defp officer_display_name(officer) do
    Map.get(officer, :name) || Map.get(officer, :field_officer_name) || "Officer"
  end

  # Initials for the header avatar, e.g. "Paul Olukayode" -> "PO".
  defp initials(nil), do: "?"

  defp initials(name) when is_binary(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
    |> case do
      "" -> "?"
      value -> value
    end
  end

  defp initials(_), do: "?"

  # Builds the onclick JS for the call button. The detail is JSON-encoded so a
  # quote in an officer's name can't break out of the attribute or the script.
  defp sip_call_js(officer) do
    detail =
      Jason.encode!(%{
        number: to_string(Map.get(officer, :user_id)),
        name: officer_display_name(officer)
      })

    "window.dispatchEvent(new CustomEvent('phx:sip-call', { detail: #{detail} }))"
  end

  defp humanize_key(section, key) do
    @labels
    |> Map.get(section, %{})
    |> Map.get(key, fallback_humanize(key))
  end

  defp fallback_humanize(key) when is_binary(key) do
    key
    |> String.replace("_", " ")
    |> String.replace(~r/(?<=[a-z0-9])(?=[A-Z])/, " ")
    |> String.split(" ", trim: true)
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  # Safe display for non-boolean payload values (handles nested maps/lists).
  defp display_value(value) when value in ["", nil], do: "—"
  defp display_value(value) when is_binary(value) or is_number(value), do: value
  defp display_value(value), do: inspect(value)

  defp format_time(nil), do: "—"
  defp format_time(dt), do: Calendar.strftime(dt, "%b %-d, %Y %-I:%M %p")

  # Party Agent
  defp party_agent_value("agentClearance", 1), do: "Cleared"
  defp party_agent_value("agentClearance", 2), do: "Not Cleared"
  defp party_agent_value(_key, value), do: display_value(value)

  # PU Security
  defp pu_security_agencies(payload) do
    case payload["agencies"] do
      %{} = agencies ->
        Enum.sort_by(agencies, fn {key, _} ->
          {Enum.find_index(@agency_order, &(&1 == key)) || 999, key}
        end)

      _ ->
        []
    end
  end

  defp pu_security_total(payload) do
    payload
    |> pu_security_agencies()
    |> Enum.reduce(0, fn {_key, data}, acc -> acc + agency_count(data) end)
  end

  defp pu_security_tag_count(payload) do
    payload
    |> pu_security_agencies()
    |> Enum.reduce(0, fn {_key, data}, acc -> acc + length(agency_tags(data)) end)
  end

  defp agency_label(key), do: Map.get(@agency_labels, key, String.upcase(to_string(key)))

  defp agency_count(%{"personnelCount" => n}) when is_integer(n), do: n
  defp agency_count(_), do: 0

  defp agency_flag(data, key) when is_map(data), do: Map.get(data, key)
  defp agency_flag(_, _), do: nil

  defp agency_tags(%{"tagIds" => tags}) when is_list(tags), do: tags
  defp agency_tags(_), do: []

  defp presence_label(nil), do: "—"
  defp presence_label(""), do: "—"
  defp presence_label(value) when is_binary(value), do: fallback_humanize(String.downcase(value))
  defp presence_label(value), do: inspect(value)

  defp presence_class("present"),
    do: "bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-950/50 dark:text-emerald-400 dark:border-emerald-800/40"

  defp presence_class("absent"),
    do: "bg-rose-50 text-rose-700 border-rose-200 dark:bg-rose-950/50 dark:text-rose-400 dark:border-rose-800/40"

  defp presence_class(_),
    do: "bg-slate-100 text-slate-600 border-slate-200 dark:bg-slate-800 dark:text-slate-300 dark:border-slate-700"

  # ---------------------------------------------------------------------------
  # Shared report-panel components (same look as Ward Collation)
  # ---------------------------------------------------------------------------

  @amber_pill "bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-950/50 dark:text-amber-400 dark:border-amber-800/40"
  @pill_base "inline-flex items-center gap-1 rounded-full border px-2.5 py-0.5 text-[12px] font-semibold"

  attr :loading, :boolean, default: false
  attr :empty, :boolean, default: false
  attr :message, :string, default: "No report recorded for this officer"

  def report_state(assigns) do
    ~H"""
    <div :if={@loading} class="flex items-center justify-start gap-2 py-4 text-slate-500 dark:text-slate-400">
      <.icon name="hero-arrow-path" class="h-4 w-4 animate-spin text-indigo-500" />
      <span class="font-medium">Fetching report details...</span>
    </div>

    <div :if={!@loading && @empty} class="flex flex-col items-start justify-center rounded-xl border border-dashed border-slate-200 px-3 py-4 text-left dark:border-slate-800">
      <.icon name="hero-document-magnifying-glass" class="mb-1 h-8 w-8 text-slate-400 dark:text-slate-600" />
      <p class="font-medium text-slate-500 dark:text-slate-400">{@message}</p>
    </div>
    """
  end

  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :updated_at, :any, default: nil
  attr :passed, :integer, default: 0
  attr :total, :integer, default: 0
  slot :inner_block

  def report_hero(assigns) do
    assigns =
      assign(assigns, :pct, if(assigns.total > 0, do: round(assigns.passed / assigns.total * 100), else: 0))

    ~H"""
    <div class="relative overflow-hidden rounded-xl border border-slate-200 bg-gradient-to-br from-slate-50 to-white p-3.5 dark:border-slate-800 dark:from-slate-800/60 dark:to-slate-900">
      <div class="flex items-center justify-between gap-3">
        <div class="flex min-w-0 items-center gap-3">
          <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-indigo-50 text-indigo-600 dark:bg-indigo-500/10 dark:text-indigo-400">
            <.icon name={@icon} class="h-5 w-5" />
          </div>
          <div class="min-w-0">
            <div class="text-[10px] font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500">{@label}</div>
            <div class="mt-1 flex flex-wrap items-center gap-1.5">{render_slot(@inner_block)}</div>
          </div>
        </div>

        <div class="shrink-0 text-right">
          <div class="flex items-center justify-end gap-1 text-[10px] font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500">
            <.icon name="hero-clock" class="h-3 w-3" /> Updated
          </div>
          <div class="mt-1 font-mono text-[11px] font-semibold text-slate-700 dark:text-slate-200">{format_time(@updated_at)}</div>
        </div>
      </div>

      <div :if={@total > 0} class="mt-3">
        <div class="mb-1 flex items-center justify-between text-[11px]">
          <span class="font-medium text-slate-500 dark:text-slate-400">Checks on track</span>
          <span class="font-semibold tabular-nums text-slate-700 dark:text-slate-200">{@passed}/{@total}</span>
        </div>
        <div class="h-1.5 w-full overflow-hidden rounded-full bg-slate-200 dark:bg-slate-800">
          <div class={["h-full rounded-full transition-all duration-500", ward_bar_class(@pct)]} style={"width: #{@pct}%"}></div>
        </div>
      </div>
    </div>
    """
  end

  attr :coords, :any, required: true

  def report_location(assigns) do
    ~H"""
    <%= case @coords do %>
      <% {:ok, lat, lng} -> %>
        <div class="flex items-center justify-between rounded-xl border border-slate-200 bg-white px-3 py-2.5 dark:border-slate-800 dark:bg-slate-900/30">
          <div class="flex items-center gap-2">
            <.icon name="hero-map-pin" class="h-4 w-4 text-slate-500 dark:text-slate-400" />
            <span class="font-semibold text-slate-700 dark:text-slate-200">Location</span>
          </div>
          <a
            href={"https://www.google.com/maps?q=#{lat},#{lng}"}
            target="_blank"
            rel="noopener"
            class="inline-flex items-center gap-1.5 rounded-md bg-indigo-50 px-2 py-1 font-mono text-[11px] font-semibold text-indigo-600 transition-colors hover:bg-indigo-100 dark:bg-indigo-950/60 dark:text-indigo-400 dark:hover:bg-indigo-900/80"
          >
            <span>{lat}, {lng}</span>
            <.icon name="hero-arrow-top-right-on-square" class="h-3 w-3" />
          </a>
        </div>
      <% :none -> %>
    <% end %>
    """
  end

  attr :title, :string, required: true
  attr :icon, :string, required: true
  attr :count, :any, default: nil
  slot :inner_block, required: true

  def report_card(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-xl border border-slate-200 bg-white dark:border-slate-800 dark:bg-slate-900/30">
      <div class="flex items-center justify-between border-b border-slate-100 bg-slate-50/70 px-3 py-2 dark:border-slate-800 dark:bg-slate-900/60">
        <div class="flex items-center gap-2">
          <.icon name={@icon} class="h-4 w-4 text-slate-500 dark:text-slate-400" />
          <span class="font-semibold text-slate-700 dark:text-slate-200">{@title}</span>
        </div>
        <span :if={@count} class="text-[10px] font-medium text-slate-400 dark:text-slate-500">{@count}</span>
      </div>
      <div class="divide-y divide-slate-100 dark:divide-slate-800/60">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  # One label-left / value-right row.
  attr :label, :string, required: true
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def report_line(assigns) do
    ~H"""
    <div class={["flex items-center justify-between gap-3 px-3 py-2.5 transition-colors hover:bg-slate-50/80 dark:hover:bg-slate-800/40", @class]}>
      <span class="text-slate-500 dark:text-slate-400">{@label}</span>
      <div class="text-right font-medium text-slate-800 dark:text-slate-200">{render_slot(@inner_block)}</div>
    </div>
    """
  end

  attr :groups, :list, required: true
  attr :section, :atom, required: true
  attr :inverted, :list, default: []

  def report_groups(assigns) do
    ~H"""
    <.report_card :for={{title, icon, rows} <- @groups} title={title} icon={icon} count={"#{length(rows)} items"}>
      <.report_line :for={{field_key, value} <- rows} label={humanize_key(@section, field_key)}>
        <%= if ward_normalize(value) in [true, false, :unset] do %>
          <.ward_flag value={value} bad_when_true={field_key in @inverted} />
        <% else %>
          {report_value(@section, field_key, value)}
        <% end %>
      </.report_line>
    </.report_card>
    """
  end

  defp report_value(:presiding, "accreditationMethod", 1), do: "Manual"
  defp report_value(:presiding, "accreditationMethod", 2), do: "BVAS"
  defp report_value(:presiding, "accreditationMethod", 0), do: "Not answered"
  defp report_value(:presiding, "electionOutcome", code) when is_integer(code), do: outcome_name(code)
  defp report_value(:party_agent, key, value), do: party_agent_value(key, value)
  defp report_value(:ward_security, key, value), do: ward_collation_value(key, value)
  defp report_value(_section, _key, value), do: display_value(value)

  # Known groups first (only keys present), then anything unlisted under "Other Details".
  defp build_groups(payload, defs, hidden) do
    known = Enum.flat_map(defs, fn {_t, _i, keys} -> keys end)

    grouped =
      for {title, icon, keys} <- defs,
          rows = for(k <- keys, Map.has_key?(payload, k), do: {k, payload[k]}),
          rows != [],
          do: {title, icon, rows}

    other = payload |> Map.drop(hidden ++ known) |> Enum.sort()

    if other == [], do: grouped, else: grouped ++ [{"Other Details", "hero-squares-2x2", other}]
  end

  # {passed, total} over every answered yes/no row.
  defp report_score(groups, inverted) do
    groups
    |> Enum.flat_map(fn {_title, _icon, rows} -> rows end)
    |> Enum.reduce({0, 0}, fn {key, value}, {passed, total} ->
      case ward_normalize(value) do
        answer when answer in [true, false] ->
          good? = if key in inverted, do: answer == false, else: answer == true
          {if(good?, do: passed + 1, else: passed), total + 1}

        _ ->
          {passed, total}
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Presiding Officer
  # ---------------------------------------------------------------------------

  @presiding_groups [
    {"Arrival & Process", "hero-clock",
     ~w(arrivalTime numberOfInecOfficial isInecOfficialWearingTag isSecurityPersonnelPresent)},
    {"Accreditation & Voting", "hero-check-badge",
     ~w(hasAccredCommence accreditationMethod isVotersVerifyWithBvas hasVolingCommence electionOutcome)},
    {"BVAS", "hero-device-phone-mobile", ~w(isBvnMachineAvail isBvbDeviceGoodCond)}
  ]

  # Keys that are shown elsewhere (or are metadata) and must not appear under "Other Details".
  @presiding_meta ~w(isLat isLng elections electionMaterials leadElectionType leadElectionName trailElectionType trailElectionName)

  # Older payloads (before electionMaterials existed) sent one flat set of keys per election slot.
  @presiding_legacy_groups [
    {"Leading Election", "hero-user-circle",
     ~w(isEc8ResultSheetPresentLeading isEc60eAvailLeading isBallotPaperAvailLeading isBallotBoxEmptyAndSecure_leading isBallotShownEmptyToAgent_leading isEc8ResultSheetPresent_leading isEc60eAvail_leading isBallotPaperAvail_leading)},
    {"Trailing Election", "hero-user-circle",
     ~w(isEc8ResultSheetPresentTrail isEc60eAvailTrail isBallotPaperAvailTrail isBallotBoxEmptyAndSecureTrail isBallotShownEmptyToAgentTrail isEc8ResultSheetPresent_trail isEc60eAvail_trail isBallotPaperAvail_trail isBallotBoxEmptyAndSecure_trail isBallotShownEmptyToAgent_trail)},
    {"Reps (Trailing)", "hero-user-circle",
     ~w(isRepEc8ResultSheetPresentTrail isRepEc60eAvailTrail isRepBallotPaperAvailTrail isRepBallotBoxEmptyAndSecureTrail isRepBallotShownEmptyToAgentTrail)}
  ]

  @presiding_legacy_keys Enum.flat_map(@presiding_legacy_groups, fn {_t, _i, keys} -> keys end)

  @material_fields ~w(ec8aPresent ec60ePresent ballotPapersPresent boxSecure boxShownEmpty)

  @outcome_names %{0 => "Not answered", 1 => "Ongoing", 2 => "Collation", 3 => "Concluded", 4 => "Cancelled", 5 => "Disrupted"}

  attr :report, :any, required: true

  def presiding_panel(assigns) do
    payload = assigns.report.payload || %{}
    materials = election_materials(payload)

    {defs, hidden} =
      if materials == [] do
        {@presiding_groups ++ @presiding_legacy_groups, @presiding_meta}
      else
        {@presiding_groups, @presiding_meta ++ @presiding_legacy_keys}
      end

    groups = build_groups(payload, defs, hidden)
    score_groups = groups ++ Enum.map(materials, fn m -> {m.title, nil, m.rows} end)
    {passed, total} = report_score(score_groups, [])

    voting? = ward_normalize(payload["hasVolingCommence"]) == true
    outcome = payload["electionOutcome"]

    assigns =
      assigns
      |> assign(:groups, groups)
      |> assign(:materials, materials)
      |> assign(:passed, passed)
      |> assign(:total, total)
      |> assign(:pill_label, if(voting?, do: "Voting Commenced", else: "Voting Not Started"))
      |> assign(:pill_class, [@pill_base, if(voting?, do: ward_tone_class(:good), else: @amber_pill)])
      |> assign(:outcome_label, if(is_integer(outcome) and outcome > 0, do: outcome_name(outcome)))
      |> assign(:outcome_class, [@pill_base, outcome_class(outcome)])
      |> assign(:coords, party_agent_coords(payload))
      |> assign(:updated_at, Map.get(assigns.report, :updated_at))

    ~H"""
    <div class="space-y-3 pt-1">
      <.report_hero icon="hero-user" label="Presiding Officer" updated_at={@updated_at} passed={@passed} total={@total}>
        <span class={@pill_class}>{@pill_label}</span>
        <span :if={@outcome_label} class={@outcome_class}>{@outcome_label}</span>
      </.report_hero>

      <.report_location coords={@coords} />

      <.report_groups groups={@groups} section={:presiding} />

      <!-- One card per election, named from the elections list the client sent -->
      <.report_card :for={m <- @materials} title={m.title} icon="hero-archive-box" count={m.label}>
        <.report_line :for={{field_key, value} <- m.rows} label={humanize_key(:presiding, field_key)}>
          <.ward_flag value={value} />
        </.report_line>
      </.report_card>
    </div>
    """
  end

  defp outcome_name(code), do: Map.get(@outcome_names, code, "Unknown")

  defp outcome_class(3), do: ward_tone_class(:good)
  defp outcome_class(code) when code in [4, 5], do: ward_tone_class(:bad)
  defp outcome_class(2), do: @amber_pill

  defp outcome_class(1),
    do: "bg-sky-50 text-sky-700 border-sky-200 dark:bg-sky-950/50 dark:text-sky-400 dark:border-sky-800/40"

  defp outcome_class(_), do: ward_tone_class(:neutral)

  # leadsType => %{name:, id:} from the "elections" list the client sends.
  # Falls back to the lead/trail names only when the list is missing.
  defp election_names(payload) do
    from_list =
      for %{} = e <- List.wrap(payload["elections"]), is_integer(e["leadsType"]), into: %{} do
        {e["leadsType"], %{name: e["name"], id: e["id"]}}
      end

    fallback =
      for {type, name} <- [
            {payload["leadElectionType"], payload["leadElectionName"]},
            {payload["trailElectionType"], payload["trailElectionName"]}
          ],
          is_integer(type),
          is_binary(name),
          name != "",
          into: %{} do
        {type, %{name: name, id: nil}}
      end

    Map.merge(fallback, from_list)
  end

  # One entry per election in payload["electionMaterials"], sorted by electionType.
  defp election_materials(payload) do
    case payload["electionMaterials"] do
      %{} = by_type when map_size(by_type) > 0 ->
        names = election_names(payload)

        by_type
        |> Enum.flat_map(fn {key, mats} ->
          with %{} <- mats, type when is_integer(type) <- material_type(key, mats) do
            [{type, mats}]
          else
            _ -> []
          end
        end)
        |> Enum.sort_by(fn {type, _mats} -> type end)
        |> Enum.map(fn {type, mats} ->
          election = Map.get(names, type, %{})

          %{
            title: "#{election[:name] || "Election #{type}"} Materials",
            label: if(election[:id], do: "Election ID #{election[:id]} · Type #{type}", else: "Type #{type}"),
            rows: for(f <- @material_fields, Map.has_key?(mats, f), do: {f, mats[f]})
          }
        end)

      _ ->
        []
    end
  end

  # The election type is stored inside each entry; the map key is the same number.
  defp material_type(key, mats) do
    case mats["electionType"] do
      type when is_integer(type) ->
        type

      _ ->
        case Integer.parse(to_string(key)) do
          {n, _} -> n
          :error -> nil
        end
    end
  end

  # ---------------------------------------------------------------------------
  # PU Security Checklist
  # ---------------------------------------------------------------------------

  @pu_security_groups [
    {"Incidents & Order", "hero-exclamation-triangle",
     ~w(isMaintainingOrder isBallotsSnached isElectionCanceled isVotingDisruptedByViolence isUnauthorizedInfluenceObserved isObserversMainainingDistance)}
  ]

  @pu_security_inverted ~w(isBallotsSnached isElectionCanceled isVotingDisruptedByViolence isUnauthorizedInfluenceObserved)

  attr :report, :any, required: true

  def pu_security_panel(assigns) do
    payload = assigns.report.payload || %{}
    groups = build_groups(payload, @pu_security_groups, ["isLat", "isLng", "agencies", "securityPresence"])
    {passed, total} = report_score(groups, @pu_security_inverted)

    assigns =
      assigns
      |> assign(:payload, payload)
      |> assign(:groups, groups)
      |> assign(:passed, passed)
      |> assign(:total, total)
      |> assign(:inverted, @pu_security_inverted)
      |> assign(:personnel, pu_security_total(payload))
      |> assign(:tag_count, pu_security_tag_count(payload))
      |> assign(:agencies, pu_security_agencies(payload))
      |> assign(:coords, party_agent_coords(payload))
      |> assign(:updated_at, Map.get(assigns.report, :updated_at))
      |> assign(:pill_base, @pill_base)

    ~H"""
    <div class="space-y-3 pt-1">
      <.report_hero icon="hero-shield-check" label="Security Presence" updated_at={@updated_at} passed={@passed} total={@total}>
        <span class={[@pill_base, presence_class(@payload["securityPresence"])]}>
          {presence_label(@payload["securityPresence"])}
        </span>
      </.report_hero>

      <!-- Totals -->
      <div class="grid grid-cols-2 gap-3">
        <div class="flex items-center justify-between gap-3 rounded-xl border border-slate-200 bg-white px-3 py-3 dark:border-slate-800 dark:bg-slate-900/30">
          <div class="min-w-0">
            <div class="text-[10px] font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500">Total Security Personnel</div>
            <div class="mt-1 text-2xl font-semibold tabular-nums text-slate-900 dark:text-slate-100">{@personnel}</div>
          </div>
          <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-indigo-50 text-indigo-600 dark:bg-indigo-500/10 dark:text-indigo-400">
            <.icon name="hero-users" class="h-5 w-5" />
          </div>
        </div>

        <div class="flex items-center justify-between gap-3 rounded-xl border border-slate-200 bg-white px-3 py-3 dark:border-slate-800 dark:bg-slate-900/30">
          <div class="min-w-0">
            <div class="text-[10px] font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500">Security Tag Nos</div>
            <div class="mt-1 text-2xl font-semibold tabular-nums text-slate-900 dark:text-slate-100">{@tag_count}</div>
          </div>
          <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-indigo-50 text-indigo-600 dark:bg-indigo-500/10 dark:text-indigo-400">
            <.icon name="hero-tag" class="h-5 w-5" />
          </div>
        </div>
      </div>

      <.report_location coords={@coords} />

      <.report_card :for={{agency, data} <- @agencies} title={agency_label(agency)} icon="hero-shield-exclamation" count={"#{agency_count(data)} personnel"}>
        <.report_line label="Personnel">
          <span class="font-semibold tabular-nums">{agency_count(data)}</span>
        </.report_line>
        <.report_line label="Armed"><.bool_value value={agency_flag(data, "isArmed")} /></.report_line>
        <.report_line label="Arrived with INEC"><.bool_value value={agency_flag(data, "isArrivedWithInec")} /></.report_line>
        <.report_line label="Uniform Compliant"><.bool_value value={agency_flag(data, "isUniformedCompliant")} /></.report_line>
        <.report_line label="Security Tag Nos">
          <span :if={agency_tags(data) == []} class="text-slate-400 dark:text-slate-500">None</span>
          <div :if={agency_tags(data) != []} class="flex flex-wrap justify-end gap-1">
            <span
              :for={tag <- agency_tags(data)}
              class="rounded-md bg-indigo-50 px-1.5 py-0.5 font-mono text-[11px] font-semibold text-indigo-600 dark:bg-indigo-950/60 dark:text-indigo-400"
            >
              {tag}
            </span>
          </div>
        </.report_line>
      </.report_card>

      <.report_groups groups={@groups} section={:pu_security} inverted={@inverted} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Party Agent
  # ---------------------------------------------------------------------------

  @party_agent_groups [
    {"Arrival & Clearance", "hero-identification",
     ~w(agentArrivalTime isArrivalTimeRecorded clearedTime isAgentVerifiedByInec isAtAssignedUnit)},
    {"Coordination", "hero-chat-bubble-left-right",
     ~w(isCoordinatorPresent isCoordinatorBriefingReceived isWardCollationChannelEstablished)}
  ]

  attr :report, :any, required: true

  def party_agent_panel(assigns) do
    payload = assigns.report.payload || %{}
    groups = build_groups(payload, @party_agent_groups, ["isLat", "isLng", "agentClearance"])
    {passed, total} = report_score(groups, [])

    {pill_label, pill_tone} =
      case payload["agentClearance"] do
        1 -> {"Cleared", ward_tone_class(:good)}
        2 -> {"Not Cleared", ward_tone_class(:bad)}
        _ -> {"Clearance Pending", @amber_pill}
      end

    assigns =
      assigns
      |> assign(:groups, groups)
      |> assign(:passed, passed)
      |> assign(:total, total)
      |> assign(:pill_label, pill_label)
      |> assign(:pill_class, [@pill_base, pill_tone])
      |> assign(:coords, party_agent_coords(payload))
      |> assign(:updated_at, Map.get(assigns.report, :updated_at))

    ~H"""
    <div class="space-y-3 pt-1">
      <.report_hero icon="hero-users" label="INEC Clearance" updated_at={@updated_at} passed={@passed} total={@total}>
        <span class={@pill_class}>{@pill_label}</span>
      </.report_hero>
      <.report_location coords={@coords} />
      <.report_groups groups={@groups} section={:party_agent} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Ward Collation
  # ---------------------------------------------------------------------------

  # Section cards shown in the Ward Collation panel, in display order.
  @ward_groups [
    {"Party Agents", "hero-users",
     ~w(partyAgentMovement isPartyAgentsArriveAtCollationCenter isPartyAgentsProceedToWard isAgentsDeniedAccess)},
    {"Security & Materials", "hero-shield-check",
     ~w(materialsGuarded securityPersonnelPresent presidingOfficerIdentified)},
    {"EC8B Forms", "hero-document-check", ~w(isEc8bCompleted isEc8bCopiesIssued)},
    {"Integrity", "hero-exclamation-triangle",
     ~w(isBriberyAttemptDetected isPersonnelInfluencingOfficer)}
  ]

  # For these keys "Yes" is the bad answer (shown red) and "No" is the good one.
  @ward_inverted ~w(isAgentsDeniedAccess isBriberyAttemptDetected isPersonnelInfluencingOfficer)

  @ward_hidden ~w(isLat isLng collationStatus)

  attr :report, :any, required: true

  def ward_collation_panel(assigns) do
    payload = assigns.report.payload || %{}
    {passed, total} = ward_score(payload)

    assigns =
      assigns
      |> assign(:payload, payload)
      |> assign(:status, payload["collationStatus"])
      |> assign(:passed, passed)
      |> assign(:total, total)
      |> assign(:pct, if(total > 0, do: round(passed / total * 100), else: 0))
      |> assign(:groups, ward_groups(payload))
      |> assign(:coords, party_agent_coords(payload))
      |> assign(:updated_at, Map.get(assigns.report, :updated_at))

    ~H"""
    <div class="space-y-3 pt-1">
      <!-- Hero: collation status + last updated -->
      <div class="relative overflow-hidden rounded-xl border border-slate-200 bg-gradient-to-br from-slate-50 to-white p-3.5 dark:border-slate-800 dark:from-slate-800/60 dark:to-slate-900">
        <div class="flex items-center justify-between gap-3">
          <div class="flex items-center gap-3 min-w-0">
            <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-indigo-50 text-indigo-600 dark:bg-indigo-500/10 dark:text-indigo-400">
              <.icon name="hero-building-office-2" class="h-5 w-5" />
            </div>
            <div class="min-w-0">
              <div class="text-[10px] font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500">
                Collation Status
              </div>
              <span class={["mt-1 inline-flex items-center rounded-full border px-2.5 py-0.5 text-[12px] font-semibold", ward_status_class(@status)]}>
                {ward_collation_value("collationStatus", @status)}
              </span>
            </div>
          </div>

          <div class="text-right shrink-0">
            <div class="flex items-center justify-end gap-1 text-[10px] font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500">
              <.icon name="hero-clock" class="h-3 w-3" /> Updated
            </div>
            <div class="mt-1 font-mono text-[11px] font-semibold text-slate-700 dark:text-slate-200">
              {format_time(@updated_at)}
            </div>
          </div>
        </div>

        <!-- Checklist progress -->
        <div :if={@total > 0} class="mt-3">
          <div class="mb-1 flex items-center justify-between text-[11px]">
            <span class="font-medium text-slate-500 dark:text-slate-400">Checks on track</span>
            <span class="font-semibold tabular-nums text-slate-700 dark:text-slate-200">{@passed}/{@total}</span>
          </div>
          <div class="h-1.5 w-full overflow-hidden rounded-full bg-slate-200 dark:bg-slate-800">
            <div
              class={["h-full rounded-full transition-all duration-500", ward_bar_class(@pct)]}
              style={"width: #{@pct}%"}
            >
            </div>
          </div>
        </div>
      </div>

      <!-- Location -->
      <%= case @coords do %>
        <% {:ok, lat, lng} -> %>
          <div class="flex items-center justify-between rounded-xl border border-slate-200 bg-white px-3 py-2.5 dark:border-slate-800 dark:bg-slate-900/30">
            <div class="flex items-center gap-2">
              <.icon name="hero-map-pin" class="h-4 w-4 text-slate-500 dark:text-slate-400" />
              <span class="font-semibold text-slate-700 dark:text-slate-200">Location</span>
            </div>
            <a
              href={"https://www.google.com/maps?q=#{lat},#{lng}"}
              target="_blank"
              rel="noopener"
              class="inline-flex items-center gap-1.5 rounded-md bg-indigo-50 px-2 py-1 font-mono text-[11px] font-semibold text-indigo-600 transition-colors hover:bg-indigo-100 dark:bg-indigo-950/60 dark:text-indigo-400 dark:hover:bg-indigo-900/80"
            >
              <span>{lat}, {lng}</span>
              <.icon name="hero-arrow-top-right-on-square" class="h-3 w-3" />
            </a>
          </div>
        <% :none -> %>
      <% end %>

      <!-- Grouped detail cards -->
      <div
        :for={{title, icon, rows} <- @groups}
        class="overflow-hidden rounded-xl border border-slate-200 bg-white dark:border-slate-800 dark:bg-slate-900/30"
      >
        <div class="flex items-center justify-between border-b border-slate-100 bg-slate-50/70 px-3 py-2 dark:border-slate-800 dark:bg-slate-900/60">
          <div class="flex items-center gap-2">
            <.icon name={icon} class="h-4 w-4 text-slate-500 dark:text-slate-400" />
            <span class="font-semibold text-slate-700 dark:text-slate-200">{title}</span>
          </div>
          <span class="text-[10px] font-medium text-slate-400 dark:text-slate-500">{length(rows)} items</span>
        </div>

        <div class="divide-y divide-slate-100 dark:divide-slate-800/60">
          <div
            :for={{field_key, value} <- rows}
            class="flex items-center justify-between gap-3 px-3 py-2.5 transition-colors hover:bg-slate-50/80 dark:hover:bg-slate-800/40"
          >
            <span class="text-slate-500 dark:text-slate-400">{humanize_key(:ward_security, field_key)}</span>

            <%= if ward_normalize(value) in [true, false, :unset] do %>
              <.ward_flag value={value} bad_when_true={field_key in ward_inverted()} />
            <% else %>
              <span class="text-right font-medium text-slate-800 dark:text-slate-200">
                {ward_collation_value(field_key, value)}
              </span>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :value, :any, default: nil
  attr :bad_when_true, :boolean, default: false

  def ward_flag(assigns) do
    {label, tone} = ward_flag_view(assigns.value, assigns.bad_when_true)

    assigns =
      assigns
      |> assign(:label, label)
      |> assign(:tone, tone)

    ~H"""
    <span class={["inline-flex shrink-0 items-center gap-1 rounded-full border px-2 py-0.5 text-[11px] font-medium", ward_tone_class(@tone)]}>
      <.icon name={ward_tone_icon(@tone)} class="h-3.5 w-3.5" />
      {@label}
    </span>
    """
  end

  defp ward_inverted, do: @ward_inverted

  # Normalises booleans and "YES"/"NO"/"NOT_SET" strings.
  defp ward_normalize(true), do: true
  defp ward_normalize(false), do: false
  defp ward_normalize("YES"), do: true
  defp ward_normalize("NO"), do: false
  defp ward_normalize("NOT_SET"), do: :unset
  defp ward_normalize(nil), do: :unset
  defp ward_normalize(_), do: :other

  defp ward_flag_view(value, inverted) do
    case ward_normalize(value) do
      true -> {"Yes", if(inverted, do: :bad, else: :good)}
      false -> {"No", if(inverted, do: :good, else: :bad)}
      _ -> {"Not set", :neutral}
    end
  end

  defp ward_tone_class(:good),
    do: "bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-950/50 dark:text-emerald-400 dark:border-emerald-800/40"

  defp ward_tone_class(:bad),
    do: "bg-rose-50 text-rose-700 border-rose-200 dark:bg-rose-950/50 dark:text-rose-400 dark:border-rose-800/40"

  defp ward_tone_class(:neutral),
    do: "bg-slate-100 text-slate-500 border-slate-200 dark:bg-slate-800 dark:text-slate-400 dark:border-slate-700"

  defp ward_tone_icon(:good), do: "hero-check-circle"
  defp ward_tone_icon(:bad), do: "hero-x-circle"
  defp ward_tone_icon(:neutral), do: "hero-minus-circle"

  defp ward_status_class(status) do
    value = status |> to_string() |> String.downcase()

    cond do
      value in ["", "not_set"] ->
        "bg-slate-100 text-slate-500 border-slate-200 dark:bg-slate-800 dark:text-slate-400 dark:border-slate-700"

      String.contains?(value, ["complete", "conclu", "done", "finish"]) ->
        "bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-950/50 dark:text-emerald-400 dark:border-emerald-800/40"

      String.contains?(value, ["progress", "ongoing", "pending", "start"]) ->
        "bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-950/50 dark:text-amber-400 dark:border-amber-800/40"

      true ->
        "bg-indigo-50 text-indigo-700 border-indigo-200 dark:bg-indigo-950/50 dark:text-indigo-400 dark:border-indigo-800/40"
    end
  end

  defp ward_bar_class(pct) when pct >= 80, do: "bg-emerald-500"
  defp ward_bar_class(pct) when pct >= 50, do: "bg-amber-500"
  defp ward_bar_class(_), do: "bg-rose-500"

  # {passed, total} over every answered yes/no check.
  defp ward_score(payload) do
    @ward_groups
    |> Enum.flat_map(fn {_title, _icon, keys} -> keys end)
    |> Enum.reduce({0, 0}, fn key, {passed, total} ->
      case ward_normalize(payload[key]) do
        answer when answer in [true, false] ->
          good? = if key in @ward_inverted, do: answer == false, else: answer == true
          {if(good?, do: passed + 1, else: passed), total + 1}

        _ ->
          {passed, total}
      end
    end)
  end

  # Known groups first (only keys present), then anything unlisted under "Other Details".
  defp ward_groups(payload) do
    known = Enum.flat_map(@ward_groups, fn {_t, _i, keys} -> keys end)

    grouped =
      for {title, icon, keys} <- @ward_groups,
          rows = for(k <- keys, Map.has_key?(payload, k), do: {k, payload[k]}),
          rows != [],
          do: {title, icon, rows}

    other =
      payload
      |> Map.drop(@ward_hidden ++ known)
      |> Enum.sort()

    if other == [], do: grouped, else: grouped ++ [{"Other Details", "hero-squares-2x2", other}]
  end

  defp ward_collation_value(_key, "NOT_SET"), do: "Not set"
  defp ward_collation_value(_key, "YES"), do: "Yes"
  defp ward_collation_value(_key, "NO"), do: "No"

  defp ward_collation_value(_key, value) when is_binary(value) and value != "" do
    if value == String.upcase(value), do: fallback_humanize(String.downcase(value)), else: value
  end

  defp ward_collation_value(_key, value), do: display_value(value)

  # Shared by Party Agent and Ward Collation: coordinates only if both are real numbers.
  defp party_agent_coords(payload) do
    with lat when lat not in ["", nil] <- payload["isLat"],
         lng when lng not in ["", nil] <- payload["isLng"],
         {la, _} <- Float.parse(to_string(lat)),
         {lo, _} <- Float.parse(to_string(lng)) do
      {:ok, la, lo}
    else
      _ -> :none
    end
  end
end
