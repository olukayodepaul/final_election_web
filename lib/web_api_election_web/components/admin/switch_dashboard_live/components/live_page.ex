defmodule WebApiElectionWeb.Admin.SwitchDashboardLive.Components.LivePage do
  @moduledoc "Renders the 'Live Monitor' tab: field officer table with a fixed header and scrollable body."
  use WebApiElectionWeb, :html

  @lagos_offset_seconds 3600

  @badge_green "border-emerald-500 bg-emerald-50 text-emerald-700 dark:border-emerald-400 dark:bg-emerald-500/10 dark:text-emerald-300"
  @badge_blue "border-sky-500 bg-sky-50 text-sky-700 dark:border-sky-400 dark:bg-sky-500/10 dark:text-sky-300"
  @badge_red "border-rose-500 bg-rose-50 text-rose-700 dark:border-rose-400 dark:bg-rose-500/10 dark:text-rose-300"
  @badge_grey "border-slate-300 bg-slate-50 text-slate-600 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-300"
  @badge_base "inline-flex flex-col items-center justify-center rounded-lg border px-2.5 py-1 gap-0.5 whitespace-nowrap"

  # Module attributes can't be read inside ~H, so templates call this instead.
  defp badge_base, do: @badge_base

  attr :field_officer, :any, required: true

  def live_page(assigns) do
    ~H"""
    <div class="flex flex-col h-full min-h-0">
      <%!-- Page header --%>
      <div class="shrink-0 mb-5 flex items-center justify-between gap-4">
        <div class="flex items-center gap-3">
          <div class="h-11 w-11 rounded-2xl bg-gradient-to-br from-emerald-500 to-emerald-600 text-white flex items-center justify-center shadow-lg shadow-emerald-500/30">
            <.icon name="hero-signal" class="h-6 w-6" />
          </div>
          <div>
            <h1 class="text-xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Live Monitoring</h1>
            <p class="text-[13px] text-slate-500 dark:text-slate-400">
              Field officer status, updated in real time
            </p>
          </div>
        </div>

        <div class="flex items-center gap-2 shrink-0 rounded-full border border-emerald-200 dark:border-emerald-500/20 bg-emerald-50 dark:bg-emerald-500/10 pl-2.5 pr-3 py-1">
          <span class="relative flex h-2 w-2">
            <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
            <span class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
          </span>
          <span class="text-[12px] font-medium text-emerald-700 dark:text-emerald-300">Live</span>
        </div>
      </div>

      <%!-- Stat cards --%>
      <.async_result :let={officers} assign={@field_officer}>
        <:loading></:loading>
        <:failed :let={_reason}></:failed>
        <div class="shrink-0 mb-5 grid grid-cols-2 md:grid-cols-4 gap-4">
          <.stat_card label="Officers Reporting" value={length(officers)} icon="hero-users" tone="emerald" />
          <.stat_card
            label="Voting Started"
            value={Enum.count(officers, &(&1.has_voting_commence == true))}
            icon="hero-play-circle"
            tone="sky"
          />
          <.stat_card
            label="Concluded"
            value={Enum.count(officers, &concluded?/1)}
            icon="hero-check-badge"
            tone="violet"
          />
          <.stat_card
            label="Uploaded to IReV"
            value={Enum.count(officers, &(&1.result_upload_to_irev == true))}
            icon="hero-cloud-arrow-up"
            tone="amber"
          />
        </div>
      </.async_result>

      <%!-- Table card --%>
      <div class="flex-1 min-h-0 overflow-hidden rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 shadow-sm">
        <.async_result :let={officers} assign={@field_officer}>
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

          <div
            :if={officers == []}
            class="flex flex-col items-center justify-center gap-3 py-20 text-center"
          >
            <div class="h-14 w-14 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center">
              <.icon name="hero-inbox" class="h-7 w-7 text-slate-400 dark:text-slate-500" />
            </div>
            <p class="text-sm text-slate-500 dark:text-slate-400">No field officers are reporting yet.</p>
          </div>

          <div :if={officers != []} class="h-full overflow-auto">
            <table class="w-full text-[12px] leading-tight border-collapse">
              <thead class="sticky top-0 z-10 bg-slate-50 dark:bg-slate-900 shadow-[0_1px_0_0_rgb(226_232_240)] dark:shadow-[0_1px_0_0_rgb(30_41_59)]">
                <tr class="text-[11px] font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                  <.header_cell label="Field Officer" full="Field officer assigned to this polling unit" align="left" />
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
                  <.header_cell label={"Performance \nScore"} full="Allow Party to make a quick decision" align="center" />
                </tr>
              </thead>

              <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                <tr
                  :for={v <- officers}
                  phx-click="open-live-modal"
                  phx-value-id={v.user_id}
                  class={["group cursor-pointer transition-colors", row_class(v)]}
                >
                  <td class={["px-4 py-3 align-middle whitespace-nowrap", first_cell_class(v)]}>
                    <div class="flex items-center gap-2.5">
                      <div class="h-8 w-8 shrink-0 rounded-full bg-gradient-to-br from-emerald-400 to-teal-500 text-white text-[11px] font-bold flex items-center justify-center shadow-sm">
                        {initials(Map.get(v, :field_officer_name))}
                      </div>
                      <span class="font-semibold text-slate-800 dark:text-slate-100">
                        {Map.get(v, :field_officer_name) || "—"}
                      </span>
                    </div>
                  </td>

                  <td class="px-4 py-3 align-middle whitespace-nowrap"><.loc_cell name={v.pu_name} code={v.pu_code} /></td>
                  <td class="px-4 py-3 align-middle whitespace-nowrap"><.loc_cell name={v.ward_name} code={v.ward_code} /></td>
                  <td class="px-4 py-3 align-middle whitespace-nowrap"><.loc_cell name={v.lg_name} code={v.lg_code} /></td>
                  <td class="px-4 py-3 align-middle whitespace-nowrap"><.loc_cell name={v.state_name} code={v.state_code} /></td>

                  <td class="px-4 py-3 align-middle whitespace-nowrap text-center tabular-nums font-mono font-semibold text-slate-700 dark:text-slate-300">{v.rgv}</td>
                  <td class="px-4 py-3 align-middle whitespace-nowrap text-center tabular-nums font-mono font-semibold text-slate-700 dark:text-slate-300">{v.pc}</td>

                  <td class="px-4 py-3 align-middle text-center">
                    <.agent_arrival_badge present={v.is_agent_at_polling_unit} time={v.arrival_time} />
                  </td>

                  <td class="px-4 py-3 align-middle text-center">
                    <.agent_cleared_badge
                      cleared={v.did_inec_clear_agent}
                      time={v.did_inec_clear_agent_time}
                    />
                  </td>

                  <td class="px-4 py-3 align-middle text-center">
                    <.security_badge value={v.security_present} time={v.security_present_time} />
                  </td>

                  <td class="px-4 py-3 align-middle text-center">
                    <.inec_arrival_badge time={v.inec_ar_time} />
                  </td>

                  <td class="px-4 py-3 align-middle whitespace-nowrap text-center tabular-nums font-mono font-semibold text-slate-700 dark:text-slate-300">{v.official_no || 0}</td>

                  <td class="px-4 py-3 align-middle text-center">
                    <.bvas_available_badge
                      available={v.is_bvas_available}
                      time={v.is_bvas_available_time}
                    />
                  </td>

                  <td class="px-4 py-3 align-middle text-center">
                    <.bvas_working_badge
                      working={v.is_bvas_working}
                      time={v.is_bvas_working_time}
                    />
                  </td>

                  <td class="px-4 py-3 align-middle text-center">
                    <.arrival_badge present={v.has_accr_commence} time={v.accr_started_at} />
                  </td>

                  <td class="px-4 py-3 align-middle text-center">
                    <.bvas_accreditation_badge
                      verified={v.is_voters_verify_with_bvas}
                      time={v.is_voters_verify_with_bvas_time}
                    />
                  </td>

                  <td class="px-4 py-3 align-middle text-center">
                    <.arrival_badge
                      present={v.has_voting_commence}
                      time={v.voting_started_at}
                    />
                  </td>

                  <td class="px-4 py-3 align-middle text-center">
                    <.conclusion_badge value={v.is_conclusive} time={v.is_conclusive_time} />
                  </td>

                  <td class="px-4 py-3 align-middle text-center">
                    <.irev_upload_badge
                      uploaded={v.result_upload_to_irev}
                      time={v.result_upload_to_irev_time}
                    />
                  </td>

                  <td class="px-4 py-3 align-middle text-center">
                    <.pu_officer_badge
                      status={v.is_pu_officer_at_collation_center}
                      time={v.is_pu_officer_at_collation_center_ar_time}
                    />
                  </td>

                  <td class="px-4 py-3 align-middle text-center">
                    <.collation_outcome_badge
                      status={v.has_proceed_to_ward}
                      time={v.collation_status_time}
                    />
                  </td>

                  <td class="px-4 py-3 align-middle text-center">
                    <.perf_badge type={v.perf_type} score={v.perf_score} time={v.perf_time} />
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

  # ---------------------------------------------------------------------------
  # Layout components
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
          <p class="mt-1 text-2xl font-bold tracking-tight tabular-nums text-slate-900 dark:text-slate-100">
            {@value}
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

  attr :name, :any, default: nil
  attr :code, :any, default: nil

  defp loc_cell(assigns) do
    ~H"""
    <div class="leading-tight">
      <div class="font-medium text-slate-800 dark:text-slate-200">{@name}</div>
      <div class="text-[11px] font-mono text-slate-400 dark:text-slate-500">{@code}</div>
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
    <th class="px-4 py-3.5 align-bottom min-w-[90px]" title={@full}>
      <div class={["flex items-center gap-1", @align_class]}>
        <span class={["whitespace-pre-line leading-snug", @align == "center" && "text-center"]}>{@label}</span>
      </div>
    </th>
    """
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp initials(nil), do: "?"

  defp initials(name) do
    name
    |> to_string()
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

  defp concluded?(v) do
    case Map.get(v, :is_conclusive) do
      true -> true
      1 -> true
      "1" -> true
      val when is_binary(val) -> val |> String.trim() |> String.downcase() == "concluded"
      _ -> false
    end
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
  # Performance (winning / losing)
  # ---------------------------------------------------------------------------

  # Returns :winning | :losing | :none
  defp perf_state(v) when is_map(v), do: v |> Map.get(:perf_type) |> perf_state()

  defp perf_state(val) when is_binary(val) do
    case val |> String.trim() |> String.downcase() do
      "winning" -> :winning
      "losing" -> :losing
      _ -> :none
    end
  end

  defp perf_state(val) when val in [:winning, :losing], do: val
  defp perf_state(_), do: :none

  defp losing?(v), do: perf_state(v) == :losing

  # Score arrives as a percentage number (10, 11, ... 100). Returns "NN%" or nil.
  defp format_score(val) when is_integer(val), do: "#{val}%"
  defp format_score(val) when is_float(val), do: "#{round(val)}%"

  defp format_score(val) when is_binary(val) do
    case val |> String.trim() |> String.trim_trailing("%") |> String.trim() do
      "" -> nil
      num -> num <> "%"
    end
  end

  defp format_score(_), do: nil

  # ── Performance score badge ──
  attr :type, :any, default: nil
  attr :score, :any, default: nil
  attr :time, :any, default: nil

  defp perf_badge(assigns) do
    assigns =
      assigns
      |> assign(:state, perf_state(assigns.type))
      |> assign(:score_text, format_score(assigns.score))

    ~H"""
    <div class="flex justify-center">
      <div class={[badge_base(), perf_color(@state)]}>
        <span class="text-[11px] font-semibold leading-tight uppercase">
          {perf_label(@state)}
        </span>
        <span :if={@state != :none and @score_text} class="text-[13px] font-bold font-mono leading-none tabular-nums">
          {@score_text}
        </span>
        <span
          :if={@state != :none and has_time?(@time)}
          class="text-[10px] font-mono leading-none opacity-80"
        >
          {format_time(@time)}
        </span>
      </div>
    </div>
    """
  end

  defp perf_label(:winning), do: "WINNING"
  defp perf_label(:losing), do: "LOSING"
  defp perf_label(_), do: "-"

  defp perf_color(:winning), do: @badge_green
  defp perf_color(:losing), do: @badge_red
  defp perf_color(_), do: @badge_grey

  # ---------------------------------------------------------------------------
  # Row colour
  # ---------------------------------------------------------------------------

  defp row_class(v) do
    good? =
      v.has_accr_commence && v.has_voting_commence &&
        v.security_present == "present" && v.is_bvas_working

    cond do
      # LOSING overrides everything: alert for the party agent to act quickly.
      losing?(v) ->
        "bg-rose-300 dark:bg-rose-800/70 hover:bg-rose-400 dark:hover:bg-rose-800/90"

      v.is_conclusive_time ->
        "bg-rose-50/50 dark:bg-rose-950/20 hover:bg-rose-50 dark:hover:bg-rose-950/30"

      good? ->
        "bg-emerald-50/50 dark:bg-emerald-950/20 hover:bg-emerald-50 dark:hover:bg-emerald-950/30"

      true ->
        "hover:bg-slate-50 dark:hover:bg-slate-800/50"
    end
  end

  # Red left border on the first cell of a losing row so it reads as flagged.
  defp first_cell_class(v) do
    if losing?(v), do: "border-l-4 border-rose-600 dark:border-rose-400", else: nil
  end

  # ── Party agent cleared by PO: DB value is "Cleared" or "Not Cleared" ──
  defp agent_cleared_badge(assigns) do
    assigns =
      assigns
      |> assign_new(:time, fn -> nil end)
      |> assign(:state, cleared_state(assigns.cleared))

    ~H"""
    <div class="flex justify-center">
      <div class={[badge_base(), cleared_color(@state)]}>
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
  defp cleared_color(_), do: @badge_grey

  # ── BVAS availability ──
  defp bvas_available_badge(assigns) do
    assigns = assign_new(assigns, :time, fn -> nil end)

    ~H"""
    <div class="flex justify-center">
      <div class={[badge_base(), bvas_available_color(@available)]}>
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
  defp bvas_available_color(_), do: @badge_grey

  # ── BVAS functionality status ──
  defp bvas_working_badge(assigns) do
    assigns = assign_new(assigns, :time, fn -> nil end)

    ~H"""
    <div class="flex justify-center">
      <div class={[badge_base(), bvas_working_color(@working)]}>
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
  defp bvas_working_color(_), do: @badge_grey

  # ── Result upload to IReV ──
  defp irev_upload_badge(assigns) do
    assigns = assign_new(assigns, :time, fn -> nil end)

    ~H"""
    <div class="flex justify-center">
      <div class={[badge_base(), irev_upload_color(@uploaded)]}>
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
  defp irev_upload_color(_), do: @badge_grey

  # ── Polling unit voting progress ──
  defp conclusion_badge(assigns) do
    assigns = assign_new(assigns, :time, fn -> nil end)

    ~H"""
    <div class="flex justify-center">
      <div class={[badge_base(), conclusion_color(@value)]}>
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
    <div class="flex justify-center">
      <span class={[badge_base(), "text-[11px] font-semibold uppercase", security_color(@value)]}>
        <span>{@value || "-"}</span>
        <span
          :if={@value not in [nil, ""] and has_time?(@time)}
          class="text-[10px] font-mono font-normal leading-none opacity-80 normal-case"
        >
          {format_time(@time)}
        </span>
      </span>
    </div>
    """
  end

  defp security_color("present"), do: @badge_green
  defp security_color(value) when value in ["absent", "left"], do: @badge_red
  defp security_color(_), do: @badge_grey

  # ── Party agent attendance ──
  defp agent_arrival_badge(assigns) do
    ~H"""
    <div class="flex justify-center">
      <div class={[badge_base(), agent_arrival_color(@present)]}>
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
  defp agent_arrival_color(_), do: @badge_grey

  # ── Accreditation / voting started ──
  defp arrival_badge(assigns) do
    ~H"""
    <div class="flex justify-center">
      <div class={[badge_base(), arrival_color(@present)]}>
        <span class="text-[11px] font-semibold leading-tight uppercase">
          {arrival_label(@present)}
        </span>
        <span :if={has_time?(@time)} class="text-[10px] font-mono leading-none opacity-80">
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
  defp arrival_color(_), do: @badge_grey

  # ── Voters accreditation: DB value is "Manual" or "Bvas" ──
  defp bvas_accreditation_badge(assigns) do
    assigns =
      assigns
      |> assign_new(:time, fn -> nil end)
      |> assign(:method, normalize_method(assigns.verified))

    ~H"""
    <div class="flex justify-center">
      <div class={[badge_base(), accreditation_color(@method)]}>
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

  defp normalize_method(val) when is_binary(val), do: val |> String.trim() |> String.downcase()
  defp normalize_method(_), do: ""

  defp accreditation_label("bvas"), do: "BVAS"
  defp accreditation_label("manual"), do: "MANUAL"
  defp accreditation_label(_), do: "-"

  defp accreditation_color("bvas"), do: @badge_green
  defp accreditation_color("manual"), do: @badge_red
  defp accreditation_color(_), do: @badge_grey

  # ── Presiding officer attendance ──
  defp inec_arrival_badge(assigns) do
    assigns = assign(assigns, :present, has_time?(assigns.time))

    ~H"""
    <div class="flex justify-center">
      <div class={[badge_base(), inec_arrival_color(@present)]}>
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

  defp normalize_status(val) when is_binary(val),
    do: val |> String.trim() |> String.replace("_", " ") |> String.downcase()

  defp normalize_status(_), do: ""

  defp status_text(val) when is_binary(val), do: val |> String.trim() |> String.upcase()
  defp status_text(_), do: "-"

  # ── Party Agent Arrival at Collation Centre ──
  defp pu_officer_badge(assigns) do
    assigns =
      assigns
      |> assign_new(:time, fn -> nil end)
      |> assign(:state, pu_officer_state(assigns.status))

    ~H"""
    <div class="flex justify-center">
      <div class={[badge_base(), pu_officer_color(@state)]}>
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

  # ── Collation Centre Progress Status ──
  defp collation_outcome_badge(assigns) do
    assigns =
      assigns
      |> assign_new(:time, fn -> nil end)
      |> assign(:state, collation_state(assigns.status))

    ~H"""
    <div class="flex justify-center">
      <div class={[badge_base(), collation_color(@state)]}>
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
