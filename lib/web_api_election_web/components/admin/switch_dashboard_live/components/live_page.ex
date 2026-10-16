defmodule WebApiElectionWeb.Admin.SwitchDashboardLive.Components.LivePage do
  @moduledoc "Renders the 'Live Monitor' tab: field officer table with a fixed header and scrollable body."
  use Phoenix.Component

  @lagos_offset_seconds 3600

  @badge_green "border-emerald-500 bg-emerald-50 text-emerald-700 dark:border-emerald-400 dark:bg-emerald-500/10 dark:text-emerald-300"
  @badge_blue "border-sky-500 bg-sky-50 text-sky-700 dark:border-sky-400 dark:bg-sky-500/10 dark:text-sky-300"
  @badge_red "border-rose-500 bg-rose-50 text-rose-700 dark:border-rose-400 dark:bg-rose-500/10 dark:text-rose-300"

  attr :field_officer, :any, required: true

  def live_page(assigns) do
    ~H"""
    <div class="flex flex-col h-full min-h-0">
      <!-- Fixed header: title stays put while the table body scrolls -->
      <div class="shrink-0 mb-4 flex items-center justify-between gap-4">
        <div>
          <h1 class="text-[26px] font-semibold tracking-tight">Live Monitoring</h1>
          <p class="text-[13px] text-muted dark:text-slate-400 mt-0.5">
            Field officer status, updated in real time
          </p>
        </div>

        <.async_result :let={officers} assign={@field_officer}>
          <:loading></:loading>
          <:failed :let={_reason}></:failed>
          <div class="flex items-center gap-2 shrink-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 rounded-full pl-2.5 pr-3 py-1 shadow-sm">
            <span class="relative flex h-2 w-2">
              <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
              <span class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
            </span>
            <span class="text-[12px] font-medium text-slate-700 dark:text-slate-300 tabular-nums">
              {length(officers)} officers reporting
            </span>
          </div>
        </.async_result>
      </div>

      <!-- Scrollable body & Table container -->
      <div class="flex-1 min-h-0 border border-slate-300 dark:border-slate-700 rounded-lg overflow-hidden shadow-sm bg-white dark:bg-slate-950">
        <.async_result :let={officers} assign={@field_officer}>
          <:loading>
            <div class="flex flex-col items-center justify-center h-full p-12 bg-slate-50/50 dark:bg-slate-900/50">
              <div class="w-8 h-8 border-3 border-brand border-t-transparent rounded-full animate-spin mb-3"></div>
              <p class="text-sm text-muted dark:text-slate-400 font-medium">Fetching live officer updates...</p>
            </div>
          </:loading>

          <:failed :let={_reason}>
            <div class="p-6 text-center bg-rose-50/50 dark:bg-rose-950/20 text-rose-600 dark:text-rose-400 text-sm">
              Failed to load field officer state. Please try refreshing.
            </div>
          </:failed>

          <div class="h-full overflow-auto">
            <table class="w-full text-[12px] leading-tight border-collapse">
              <thead class="sticky top-0 z-10 shadow-[0_1px_2px_rgba(0,0,0,0.05)]">
                <tr class="text-[11px] font-semibold uppercase tracking-wider text-slate-700 dark:text-slate-300 bg-slate-100 dark:bg-slate-900 border-t border-b-2 border-slate-300 dark:border-slate-700">
                  <.header_cell label="PU" full="Polling Unit" align="left" />
                  <.header_cell label="Ward" full="Ward" align="left" />
                  <.header_cell label="LG" full="Local Government" align="left" />
                  <.header_cell label="State" full="State" align="left" />
                  <.header_cell label={"Reg.\nVoters"} full="Registered Voters" align="center" />
                  <.header_cell label="PVC" full="PVC Collected" align="center" />
                  <.header_cell label={"Party Agent \nAttendance"} full="Party Agent present at polling unit" align="center" />
                  <.header_cell label={"Party Agent \n Cleared by PO"} full="Party Agent cleared by INEC official (Cleared / Not Cleared)" align="center" />
                  <.header_cell label={"Polling Unit \n Security Attendance"} full="Security present at polling unit" align="center" />
                  <.header_cell label={"Presiding Officer \n Attendance"} full="INEC official arrival at polling unit" align="center" />
                  <.header_cell label={"Number of INEC \n Officials"} full="Number of INEC staff at polling unit" align="center" />
                  <.header_cell label={"BVAS Availability  at Polling Unit"} full="BVAS device available (Available / Not Available)" align="center" />
                  <.header_cell label={"BVAS \nFunctionality \nStatus"} full="BVAS device functioning (Working / Not Working)" align="center" />
                  <.header_cell label={"Voter Accreditation \nStatus"} full="Voter accreditation commenced" align="center" />
                  <.header_cell label={"Voter Accreditation \nMethod"} full="Voter accreditation method (Manual or BVAS)" align="center" />
                  <.header_cell label={"Voting Start \nStatus"} full="Voting commenced" align="center" />
                  <.header_cell label={"Polling Unit Voting \nProgress Status"} full="Final voting outcome at polling unit (Concluded/Cancelled)" align="center" />
                  <.header_cell label={"Result Upload to \nIReV Status"} full="Result uploaded to IReV portal" align="center" />
                  <.header_cell label={"Party Agent Arrival at Collation Centre"} full="Party Agent arrival at Collation Center" align="center" />
                  <.header_cell label={"Collation Centre \nProgress Status"} full="INEC official proceeded to Ward Collation Center" align="center" />
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-200 dark:divide-slate-800">
                <tr
                  :for={v <- officers}
                  phx-click="open-live-modal"
                  phx-value-id={v.user_id}
                  class={["cursor-pointer transition-colors", row_class(v)]}
                >
                  <td class="px-3 py-2 align-middle whitespace-nowrap text-left border-r border-slate-200 dark:border-slate-800 font-medium text-slate-800 dark:text-slate-200">
                    {v.pu_name} <span class="text-slate-400 font-mono text-[11px] font-normal">({v.pu_code})</span>
                  </td>
                  <td class="px-3 py-2 align-middle whitespace-nowrap text-left border-r border-slate-200 dark:border-slate-800">{v.ward_name} <span class="text-slate-400 font-mono text-[11px]">({v.ward_code})</span></td>
                  <td class="px-3 py-2 align-middle whitespace-nowrap text-left border-r border-slate-200 dark:border-slate-800">{v.lg_name} <span class="text-slate-400 font-mono text-[11px]">({v.lg_code})</span></td>
                  <td class="px-3 py-2 align-middle whitespace-nowrap text-left border-r border-slate-200 dark:border-slate-800">{v.state_name} <span class="text-slate-400 font-mono text-[11px]">({v.state_code})</span></td>
                  <td class="px-3 py-2 align-middle whitespace-nowrap text-center tabular-nums border-r border-slate-200 dark:border-slate-800 font-mono">{v.rgv}</td>
                  <td class="px-3 py-2 align-middle whitespace-nowrap text-center tabular-nums border-r border-slate-200 dark:border-slate-800 font-mono">{v.pc}</td>

                  <td class="px-3 py-2 align-middle text-center border-r border-slate-200 dark:border-slate-800">
                    <.agent_arrival_badge present={v.is_agent_at_polling_unit} time={v.arrival_time} />
                  </td>

                  <td class="px-3 py-2 align-middle text-center border-r border-slate-200 dark:border-slate-800">
                    <.agent_cleared_badge
                      cleared={v.did_inec_clear_agent}
                      time={v.did_inec_clear_agent_time}
                    />
                  </td>

                  <td class="px-3 py-2 align-middle text-center border-r border-slate-200 dark:border-slate-800">
                    <.security_badge value={v.security_present} time={v.security_present_time} />
                  </td>

                  <td class="px-3 py-2 align-middle text-center border-r border-slate-200 dark:border-slate-800">
                    <.inec_arrival_badge time={v.inec_ar_time} />
                  </td>

                  <td class="px-3 py-2 align-middle whitespace-nowrap text-center tabular-nums border-r border-slate-200 dark:border-slate-800 font-mono">{v.official_no || 0}</td>

                  <td class="px-3 py-2 align-middle text-center border-r border-slate-200 dark:border-slate-800">
                    <.bvas_available_badge
                      available={v.is_bvas_available}
                      time={v.is_bvas_available_time}
                    />
                  </td>

                  <td class="px-3 py-2 align-middle text-center border-r border-slate-200 dark:border-slate-800">
                    <.bvas_working_badge
                      working={v.is_bvas_working}
                      time={v.is_bvas_working_time}
                    />
                  </td>

                  <td class="px-3 py-2 align-middle text-center border-r border-slate-200 dark:border-slate-800">
                    <.arrival_badge present={v.has_accr_commence} time={v.accr_started_at} />
                  </td>

                  <td class="px-3 py-2 align-middle text-center border-r border-slate-200 dark:border-slate-800">
                    <.bvas_accreditation_badge
                      verified={v.is_voters_verify_with_bvas}
                      time={v.is_voters_verify_with_bvas_time}
                    />
                  </td>

                  <td class="px-3 py-2 align-middle text-center border-r border-slate-200 dark:border-slate-800">
                    <.arrival_badge
                      present={v.has_voting_commence}
                      time={v.voting_started_at}
                    />
                  </td>

                  <td class="px-3 py-2 align-middle text-center border-r border-slate-200 dark:border-slate-800">
                    <.conclusion_badge value={v.is_conclusive} time={v.is_conclusive_time} />
                  </td>

                  <td class="px-3 py-2 align-middle text-center border-r border-slate-200 dark:border-slate-800">
                    <.irev_upload_badge
                      uploaded={v.result_upload_to_irev}
                      time={v.result_upload_to_irev_time}
                    />
                  </td>

                  <td class="px-3 py-2 align-middle text-center border-r border-slate-200 dark:border-slate-800">
                    <.pu_officer_badge
                      status={v.is_pu_officer_at_collation_center}
                      time={v.is_pu_officer_at_collation_center_ar_time}
                    />
                  </td>

                  <td class="px-3 py-2 align-middle text-center border-r border-slate-200 dark:border-slate-800">
                    <.collation_outcome_badge
                      status={v.has_proceed_to_ward}
                      time={v.collation_status_time}
                    />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </.async_result>
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :full, :string, required: true
  attr :align, :string, default: "left"

  defp header_cell(assigns) do
    align_class =
      case assigns.align do
        "center" -> "text-center justify-center"
        "right" -> "text-right justify-end"
        _ -> "text-left justify-start"
      end

    assigns = assign(assigns, :align_class, align_class)

    ~H"""
    <th class="px-2.5 py-2.5 align-bottom min-w-[85px] border-r border-slate-300 dark:border-slate-700 last:border-r-0" title={@full}>
      <div class={["flex items-center gap-1", @align_class]}>
        <span class="whitespace-pre-line leading-snug text-center">{@label}</span>
      </div>
    </th>
    """
  end

  # ---------------------------------------------------------------------------
  # Time helpers
  # ---------------------------------------------------------------------------

  defp format_time(nil), do: ""
  defp format_time(""), do: ""

  defp format_time(datetime_str) when is_binary(datetime_str) do
    normalized = String.replace(datetime_str, " ", "T")

    case DateTime.from_iso8601(normalized) do
      {:ok, dt, _offset} ->
        format_time(dt)

      _ ->
        case String.split(normalized, "T") do
          [_date, time_part] ->
            time_part |> String.split("Z") |> List.first() |> String.slice(0, 8)

          _ ->
            datetime_str
        end
    end
  end

  defp format_time(%DateTime{} = dt) do
    dt |> DateTime.add(@lagos_offset_seconds, :second) |> Calendar.strftime("%H:%M:%S")
  end

  defp format_time(%NaiveDateTime{} = dt) do
    dt |> NaiveDateTime.add(@lagos_offset_seconds, :second) |> Calendar.strftime("%H:%M:%S")
  end

  defp format_time(%Time{} = t), do: Calendar.strftime(t, "%H:%M:%S")
  defp format_time(_), do: ""

  defp has_time?(nil), do: false
  defp has_time?(""), do: false
  defp has_time?(_), do: true

  # ---------------------------------------------------------------------------
  # Row colour
  # ---------------------------------------------------------------------------

  defp row_class(v) do
    good? =
      v.has_accr_commence && v.has_voting_commence &&
        v.security_present == "present" && v.is_bvas_working

    cond do
      v.is_conclusive_time ->
        "bg-rose-50/60 dark:bg-rose-950/20 hover:bg-rose-50 dark:hover:bg-rose-950/30"

      good? ->
        "bg-emerald-50/60 dark:bg-emerald-950/20 hover:bg-emerald-50 dark:hover:bg-emerald-950/30"

      true ->
        "odd:bg-white even:bg-slate-50/60 dark:odd:bg-slate-950 dark:even:bg-slate-900/40 hover:bg-slate-100 dark:hover:bg-slate-800"
    end
  end

  # ── Party agent cleared by PO: DB value is "Cleared" or "Not Cleared" ──
  # Cleared = green, Not Cleared = red, anything else = neutral grey.
  defp agent_cleared_badge(assigns) do
    assigns =
      assigns
      |> assign_new(:time, fn -> nil end)
      |> assign(:state, cleared_state(assigns.cleared))

    ~H"""
    <div class="flex justify-center">
      <div class={[
        "inline-flex flex-col items-center justify-center rounded-md border px-2 py-1 gap-0.5",
        cleared_color(@state)
      ]}>
        <span class="text-[11px] font-semibold leading-tight uppercase">
          {cleared_label(@state)}
        </span>
        <span
          :if={@state != :unknown and has_time?(@time)}
          class="text-[10px] font-mono leading-none opacity-80"
        >
          {format_time(@time)}
        </span>
      </div>
    </div>
    """
  end

  # Lowercase once, then match exactly (so "not cleared" is never mistaken for "cleared").
  # Old numeric and boolean rows still work.
  defp cleared_state(val) when is_binary(val) do
    case val |> String.trim() |> String.downcase() do
      v when v in ["cleared", "1", "true"] -> :cleared
      v when v in ["not cleared", "not_cleared", "2", "false"] -> :not_cleared
      _ -> :unknown
    end
  end

  defp cleared_state(val) when val in [1, true], do: :cleared
  defp cleared_state(val) when val in [2, false], do: :not_cleared
  defp cleared_state(_), do: :unknown

  defp cleared_label(:cleared), do: "CLEARED"
  defp cleared_label(:not_cleared), do: "NOT CLEARED"
  defp cleared_label(_), do: "-"

  defp cleared_color(:cleared), do: @badge_green
  defp cleared_color(:not_cleared), do: @badge_red

  defp cleared_color(_),
    do: "border-slate-300 bg-slate-50 text-slate-600 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-300"

  # ── BVAS availability: true = Available (green), false = Not Available (red) ──
  defp bvas_available_badge(assigns) do
    assigns = assign_new(assigns, :time, fn -> nil end)

    ~H"""
    <div class="flex justify-center">
      <div class={[
        "inline-flex flex-col items-center justify-center rounded-md border px-2 py-1 gap-0.5",
        bvas_available_color(@available)
      ]}>
        <span class="text-[11px] font-semibold leading-tight uppercase">
          {bvas_available_label(@available)}
        </span>
        <span
          :if={is_boolean(@available) and has_time?(@time)}
          class="text-[10px] font-mono leading-none opacity-80"
        >
          {format_time(@time)}
        </span>
      </div>
    </div>
    """
  end

  defp bvas_available_label(true), do: "AVAILABLE"
  defp bvas_available_label(false), do: "NOT AVAILABLE"
  defp bvas_available_label(_), do: "-"

  defp bvas_available_color(true), do: @badge_green
  defp bvas_available_color(false), do: @badge_red

  defp bvas_available_color(_),
    do: "border-slate-300 bg-slate-50 text-slate-600 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-300"

  # ── BVAS functionality status: true = Working (green), false = Not Working (red) ──
  defp bvas_working_badge(assigns) do
    assigns = assign_new(assigns, :time, fn -> nil end)

    ~H"""
    <div class="flex justify-center">
      <div class={[
        "inline-flex flex-col items-center justify-center rounded-md border px-2 py-1 gap-0.5",
        bvas_working_color(@working)
      ]}>
        <span class="text-[11px] font-semibold leading-tight uppercase">
          {bvas_working_label(@working)}
        </span>
        <span
          :if={is_boolean(@working) and has_time?(@time)}
          class="text-[10px] font-mono leading-none opacity-80"
        >
          {format_time(@time)}
        </span>
      </div>
    </div>
    """
  end

  defp bvas_working_label(true), do: "WORKING"
  defp bvas_working_label(false), do: "NOT WORKING"
  defp bvas_working_label(_), do: "-"

  defp bvas_working_color(true), do: @badge_green
  defp bvas_working_color(false), do: @badge_red

  defp bvas_working_color(_),
    do: "border-slate-300 bg-slate-50 text-slate-600 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-300"

  # ── Result upload to IReV: true = Uploaded (green), false = Not Uploaded (red) ──
  defp irev_upload_badge(assigns) do
    assigns = assign_new(assigns, :time, fn -> nil end)

    ~H"""
    <div class="flex justify-center">
      <div class={[
        "inline-flex flex-col items-center justify-center rounded-md border px-2 py-1 gap-0.5",
        irev_upload_color(@uploaded)
      ]}>
        <span class="text-[11px] font-semibold leading-tight uppercase">
          {irev_upload_label(@uploaded)}
        </span>
        <span
          :if={@uploaded == true and has_time?(@time)}
          class="text-[10px] font-mono leading-none opacity-80"
        >
          {format_time(@time)}
        </span>
      </div>
    </div>
    """
  end

  defp irev_upload_label(true), do: "UPLOADED"
  defp irev_upload_label(false), do: "NOT UPLOADED"
  defp irev_upload_label(_), do: "-"

  defp irev_upload_color(true), do: @badge_green
  defp irev_upload_color(false), do: @badge_red

  defp irev_upload_color(_),
    do: "border-slate-300 bg-slate-50 text-slate-600 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-300"

  # ── Polling unit voting progress ──
  defp conclusion_badge(assigns) do
    assigns = assign_new(assigns, :time, fn -> nil end)

    ~H"""
    <div class="flex justify-center">
      <div class={[
        "inline-flex flex-col items-center justify-center rounded-md border px-2 py-1 gap-0.5",
        conclusion_color(@value)
      ]}>
        <span class="text-[11px] font-semibold leading-tight uppercase">
          {format_conclusion_text(@value)}
        </span>
        <span :if={has_time?(@time) and @time != "—"} class="text-[10px] font-mono leading-none opacity-80">
          {format_time(@time)}
        </span>
      </div>
    </div>
    """
  end

  # Concluded = Green
  defp conclusion_color(val)
       when val in [1, "1", "CONCLUDED", "Concluded", "concluded", :concluded, true],
       do: @badge_green

  # Ongoing = Blue
  defp conclusion_color(val) when val in ["ONGOING", "Ongoing", "ongoing", :ongoing],
    do: @badge_blue

  # Collation = Cyan / Light Blue
  defp conclusion_color(val) when val in ["COLLATION", "Collation", "collation", :collation],
    do: "border-cyan-500 bg-cyan-50 text-cyan-700 dark:border-cyan-400 dark:bg-cyan-500/10 dark:text-cyan-300"

  # Cancelled, Disrupted, Errors, or anything else = Red
  defp conclusion_color(_), do: @badge_red

  defp format_conclusion_text(true), do: "CONCLUDED"
  defp format_conclusion_text(false), do: "CANCELLED"
  defp format_conclusion_text(nil), do: "-"
  defp format_conclusion_text(""), do: "-"
  defp format_conclusion_text(val) when is_binary(val), do: String.upcase(val)
  defp format_conclusion_text(val) when is_atom(val), do: val |> Atom.to_string() |> String.upcase()
  defp format_conclusion_text(_), do: "-"

  # ── Security attendance ──
  defp security_badge(assigns) do
    assigns = assign_new(assigns, :time, fn -> nil end)

    ~H"""
    <span class={[
      "inline-flex flex-col items-center rounded-md border px-2 py-0.5 text-[11px] font-semibold uppercase",
      security_color(@value)
    ]}>
      <span>{@value || ""}</span>
      <span
        :if={@value not in [nil, ""] and has_time?(@time)}
        class="text-[10px] font-mono font-normal leading-none opacity-80 normal-case"
      >
        {format_time(@time)}
      </span>
    </span>
    """
  end

  defp security_color("present"), do: @badge_green
  defp security_color(value) when value in ["absent", "left"], do: @badge_red

  defp security_color(_),
    do: "border-slate-300 bg-slate-50 text-slate-600 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-300"

  # ── Party agent attendance ──
  defp agent_arrival_badge(assigns) do
    ~H"""
    <div class="flex justify-center">
      <div class={[
        "inline-flex flex-col items-center justify-center rounded-md border px-2 py-1 gap-0.5",
        agent_arrival_color(@present)
      ]}>
        <span class="text-[11px] font-semibold leading-tight uppercase">
          {agent_arrival_label(@present)}
        </span>
        <span
          :if={@present and has_time?(@time)}
          class="text-[10px] font-mono leading-none opacity-80"
        >
          {format_time(@time)}
        </span>
      </div>
    </div>
    """
  end

  defp agent_arrival_label(true), do: "PRESENT"
  defp agent_arrival_label(false), do: "ABSENT"
  defp agent_arrival_label(_), do: "-"

  defp agent_arrival_color(true), do: @badge_green
  defp agent_arrival_color(false), do: @badge_red

  defp agent_arrival_color(_),
    do: "border-slate-300 bg-slate-50 text-slate-600 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-300"

  # ── Accreditation / voting started ──
  defp arrival_badge(assigns) do
    ~H"""
    <div class="flex justify-center">
      <div class={[
        "inline-flex flex-col items-center justify-center rounded-md border px-2 py-1 gap-0.5",
        arrival_color(@present)
      ]}>
        <span class="text-[11px] font-semibold leading-tight uppercase">
          {arrival_label(@present)}
        </span>
        <span
          :if={has_time?(@time)}
          class="text-[10px] font-mono leading-none opacity-80"
        >
          {format_time(@time)}
        </span>
      </div>
    </div>
    """
  end

  defp arrival_label(true), do: "STARTED"
  defp arrival_label(false), do: "NOT STARTED"
  defp arrival_label(_), do: "-"

  defp arrival_color(true), do: @badge_green
  defp arrival_color(false), do: @badge_red

  defp arrival_color(_),
    do: "border-slate-300 bg-slate-50 text-slate-600 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-300"

  # ── Voters accreditation: DB value is "Manual" or "Bvas" ─────────────────
  # Bvas = green, Manual = red, anything else = neutral grey.
  defp bvas_accreditation_badge(assigns) do
    assigns =
      assigns
      |> assign_new(:time, fn -> nil end)
      |> assign(:method, normalize_method(assigns.verified))

    ~H"""
    <div class="flex justify-center">
      <div class={[
        "inline-flex flex-col items-center justify-center rounded-md border px-2 py-1 gap-0.5",
        accreditation_color(@method)
      ]}>
        <span class="text-[11px] font-semibold leading-tight uppercase">
          {accreditation_label(@method)}
        </span>
        <span
          :if={@method in ["bvas", "manual"] and has_time?(@time)}
          class="text-[10px] font-mono leading-none opacity-80"
        >
          {format_time(@time)}
        </span>
      </div>
    </div>
    """
  end

  # Lowercase once here, so every function below only matches "bvas" or "manual".
  defp normalize_method(val) when is_binary(val), do: val |> String.trim() |> String.downcase()
  defp normalize_method(_), do: ""

  defp accreditation_label("bvas"), do: "BVAS"
  defp accreditation_label("manual"), do: "MANUAL"
  defp accreditation_label(_), do: "-"

  defp accreditation_color("bvas"), do: @badge_green
  defp accreditation_color("manual"), do: @badge_red

  defp accreditation_color(_),
    do: "border-slate-300 bg-slate-50 text-slate-600 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-300"

  # ── Presiding officer attendance ──
  defp inec_arrival_badge(assigns) do
    assigns = assign(assigns, :present, has_time?(assigns.time))

    ~H"""
    <div class="flex justify-center">
      <div class={[
        "inline-flex flex-col items-center justify-center rounded-md border px-2 py-1 gap-0.5",
        inec_arrival_color(@present)
      ]}>
        <span class="text-[11px] font-semibold leading-tight uppercase">
          {inec_arrival_label(@present)}
        </span>
        <span :if={@present} class="text-[10px] font-mono leading-none opacity-80">
          {format_time(@time)}
        </span>
      </div>
    </div>
    """
  end

  defp inec_arrival_label(true), do: "ARRIVED"
  defp inec_arrival_label(false), do: "NOT ARRIVED"

  defp inec_arrival_color(true), do: @badge_green
  defp inec_arrival_color(false), do: @badge_red

  # ---------------------------------------------------------------------------
  # Collation columns
  # ---------------------------------------------------------------------------

  # Lowercase, trim and turn underscores into spaces, so
  # "ARRIVED_COLLATION_CENTER" and "Arrived Collation Center" both match.
  defp normalize_status(val) when is_binary(val),
    do: val |> String.trim() |> String.replace("_", " ") |> String.downcase()

  defp normalize_status(_), do: ""

  defp status_text(val) when is_binary(val), do: val |> String.trim() |> String.upcase()
  defp status_text(_), do: "-"

  # ── Party Agent Arrival at Collation Centre ──────────────────────────────
  # "ARRIVED COLLATION CENTER" = green, "DEPARTED PU" = blue, anything else
  # (including empty) = red. The time shows under the label whenever there is one.
  defp pu_officer_badge(assigns) do
    assigns =
      assigns
      |> assign_new(:time, fn -> nil end)
      |> assign(:state, pu_officer_state(assigns.status))

    ~H"""
    <div class="flex justify-center">
      <div class={[
        "inline-flex flex-col items-center justify-center rounded-md border px-2 py-1 gap-0.5",
        pu_officer_color(@state)
      ]}>
        <span class="text-[11px] font-semibold leading-tight uppercase text-center">
          {pu_officer_label(@state, @status)}
        </span>
        <span
          :if={@state != :empty and has_time?(@time)}
          class="text-[10px] font-mono leading-none opacity-80"
        >
          {format_time(@time)}
        </span>
      </div>
    </div>
    """
  end

  defp pu_officer_state(status) do
    case normalize_status(status) do
      "arrived collation center" -> :arrived
      "departed pu" -> :departed
      "" -> :empty
      _ -> :other
    end
  end

  defp pu_officer_label(:arrived, _status), do: "ARRIVED COLLATION CENTER"
  defp pu_officer_label(:departed, _status), do: "DEPARTED PU"
  defp pu_officer_label(:empty, _status), do: "-"
  defp pu_officer_label(:other, status), do: status_text(status)

  defp pu_officer_color(:arrived), do: @badge_green
  defp pu_officer_color(:departed), do: @badge_blue
  defp pu_officer_color(_), do: @badge_red

  # ── Collation Centre Progress Status ─────────────────────────────────────
  # "COMPLETED" = green. "CANCELLED", "DISRUPTED", anything else and empty = red.
  defp collation_outcome_badge(assigns) do
    assigns =
      assigns
      |> assign_new(:time, fn -> nil end)
      |> assign(:state, collation_state(assigns.status))

    ~H"""
    <div class="flex justify-center">
      <div class={[
        "inline-flex flex-col items-center justify-center rounded-md border px-2 py-1 gap-0.5",
        collation_color(@state)
      ]}>
        <span class="text-[11px] font-semibold leading-tight uppercase text-center">
          {collation_label(@state, @status)}
        </span>
        <span
          :if={@state != :empty and has_time?(@time)}
          class="text-[10px] font-mono leading-none opacity-80"
        >
          {format_time(@time)}
        </span>
      </div>
    </div>
    """
  end

  defp collation_state(status) do
    case normalize_status(status) do
      "completed" -> :completed
      "" -> :empty
      _ -> :other
    end
  end

  defp collation_label(:completed, _status), do: "COMPLETED"
  defp collation_label(:empty, _status), do: "-"
  defp collation_label(:other, status), do: status_text(status)

  defp collation_color(:completed), do: @badge_green
  defp collation_color(_), do: @badge_red
end
