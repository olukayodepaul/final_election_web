# lib/web_api_election_web/live/admin/switch_dashboard_live/components/election_result_modal.ex
defmodule WebApiElectionWeb.Admin.SwitchDashboardLive.Components.ElectionResultModal do
  use WebApiElectionWeb, :html

  # {variables key, label}
  @checks [
    {"isCountPerformInOpenView", "Count performed in open view"},
    {"wasBallotShownEmptyBeforeCount", "Ballot box shown empty before count"},
    {"arePartyAgentAllowToObservedSoring", "Party agents allowed to observe sorting"},
    {"didPresidingOfficerAnnounceResult", "Presiding officer announced result"},
    {"didAgentSignOriginalCopyOfEc8a", "Agent signed original EC8A"},
    {"didUReceiveDSignedAndStampCopyOfEc8a", "Received signed & stamped EC8A copy"},
    {"isFormEc8aUploadedToIrev", "EC8A uploaded to IReV"}
  ]

  attr :record, :any, required: true

  def election_result_modal(assigns) do
    checks = build_checks(assigns.record[:variables])
    confirmed = Enum.count(checks, &(&1.state == :yes))
    total = length(checks)

    assigns =
      assigns
      |> assign(:parties, top_parties(assigns.record[:party_results]))
      |> assign(:videos, assigns.record[:videos] || [])
      |> assign(:checks, checks)
      |> assign(:confirmed, confirmed)
      |> assign(:total_checks, total)
      |> assign(:check_pct, if(total > 0, do: round(confirmed / total * 100), else: 0))

    ~H"""
    <div
      class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/70 backdrop-blur-sm p-4"
      phx-window-keydown="close-election-result-modal"
      phx-key="escape"
    >
      <div
        class="relative flex max-h-[88vh] w-full max-w-4xl flex-col overflow-hidden rounded-2xl bg-white shadow-2xl ring-1 ring-slate-900/10 dark:bg-slate-900 dark:ring-white/10"
        phx-click-away="close-election-result-modal"
      >
        <%!-- ============ HEADER ============ --%>
        <div class="relative shrink-0 overflow-hidden bg-gradient-to-br from-slate-900 via-slate-900 to-emerald-900 px-5 py-4 text-white">
          <div class="pointer-events-none absolute -right-12 -top-12 h-40 w-40 rounded-full bg-emerald-400/10 blur-2xl"></div>
          <div class="pointer-events-none absolute -bottom-14 left-1/3 h-32 w-32 rounded-full bg-sky-400/10 blur-2xl"></div>

          <div class="relative flex items-start justify-between gap-3">
            <div class="min-w-0">
              <div class="mb-2 flex flex-wrap items-center gap-1.5">
                <span
                  :if={@record[:document_type]}
                  class="inline-flex items-center gap-1 rounded-md bg-emerald-400/15 px-1.5 py-0.5 text-[10px] font-bold tracking-wide text-emerald-300 ring-1 ring-inset ring-emerald-400/30"
                >
                  <.icon name="hero-document-check" class="h-3 w-3" />
                  {@record[:document_type]}
                </span>
                <span
                  :if={@record[:ec8a_serial_number]}
                  class="rounded-md bg-white/10 px-1.5 py-0.5 font-mono text-[10px] text-slate-200 ring-1 ring-inset ring-white/15"
                >
                  {@record[:ec8a_serial_number]}
                </span>
              </div>

              <h3 class="truncate text-base font-bold leading-tight tracking-tight sm:text-lg">
                {@record[:polling_unit]}
              </h3>

              <p class="mt-1 flex items-center gap-1 text-[12px] text-slate-300">
                <.icon name="hero-map-pin" class="h-3.5 w-3.5 shrink-0 text-emerald-300" />
                <span class="truncate">
                  {@record[:ward]}, {@record[:local_government]}, {@record[:state]}
                </span>
              </p>

              <div
                :if={@record[:election_name] || @record[:election_type]}
                class="mt-2.5 flex flex-wrap items-center gap-1.5"
              >
                <span
                  :if={@record[:election_name]}
                  class="inline-flex items-center gap-1 rounded-full bg-sky-400/15 px-2 py-0.5 text-[11px] font-medium text-sky-200 ring-1 ring-inset ring-sky-300/30"
                >
                  <.icon name="hero-flag" class="h-3 w-3" />
                  {@record[:election_name]}
                </span>
                <span
                  :if={@record[:election_type]}
                  class="inline-flex items-center gap-1 rounded-full bg-violet-400/15 px-2 py-0.5 text-[11px] font-medium text-violet-200 ring-1 ring-inset ring-violet-300/30"
                >
                  <.icon name="hero-tag" class="h-3 w-3" />
                  {humanize(@record[:election_type])}
                </span>
                <span
                  :if={@videos != []}
                  class="inline-flex items-center gap-1 rounded-full bg-rose-400/15 px-2 py-0.5 text-[11px] font-medium text-rose-200 ring-1 ring-inset ring-rose-300/30"
                >
                  <.icon name="hero-video-camera" class="h-3 w-3" />
                  {length(@videos)} {if length(@videos) == 1, do: "video", else: "videos"}
                </span>
              </div>
            </div>

            <button
              type="button"
              phx-click="close-election-result-modal"
              aria-label="Close"
              class="shrink-0 rounded-lg p-1.5 text-white/70 transition hover:bg-white/10 hover:text-white"
            >
              <.icon name="hero-x-mark" class="h-4 w-4" />
            </button>
          </div>
        </div>

        <%!-- ============ SUBMISSION STRIP ============ --%>
        <div class="grid shrink-0 grid-cols-2 gap-x-4 gap-y-3 border-b border-slate-200 bg-slate-50 px-5 py-2.5 dark:border-slate-800 dark:bg-slate-950/50 md:grid-cols-4">
          <div class="flex items-center gap-2">
            <div class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-emerald-400 to-teal-500 text-[10px] font-bold text-white shadow-sm">
              {initials(@record[:user_name])}
            </div>
            <div class="min-w-0 leading-tight">
              <p class="text-[9px] font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500">Field officer</p>
              <p class="truncate text-[12px] font-semibold text-slate-800 dark:text-slate-100">
                {@record[:user_name] || "—"}
              </p>
            </div>
          </div>

          <.meta_item label="Presiding officer" value={@record[:presiding_officer_name]} icon="hero-user-circle" />
          <.meta_item label="Submitted" value={format_datetime(@record[:inserted_at])} icon="hero-clock" />
          <.meta_item label="PU code" value={@record[:pu_code]} icon="hero-hashtag" mono />
        </div>

        <%!-- ============ BODY ============ --%>
        <div class="grid flex-1 grid-cols-1 gap-4 overflow-y-auto p-5 lg:grid-cols-5">
          <%!-- Left: sheet photo + checklist + environment videos --%>
          <div class="space-y-4 lg:col-span-2">
            <.result_panel title="Result sheet" icon="hero-photo">
              <:actions>
                <a
                  :if={@record[:upload_url]}
                  href={@record[:upload_url]}
                  target="_blank"
                  rel="noopener"
                  class="inline-flex items-center gap-1 text-[11px] font-medium text-emerald-600 hover:text-emerald-500 dark:text-emerald-400"
                >
                  Open full size
                  <.icon name="hero-arrow-top-right-on-square" class="h-3 w-3" />
                </a>
              </:actions>
              <.result_photo upload_url={@record[:upload_url]} polling_unit={@record[:polling_unit]} />
            </.result_panel>

            <.result_panel :if={@checks != []} title="Process checklist" icon="hero-clipboard-document-check">
              <:actions>
                <span class="text-[11px] font-semibold text-slate-600 dark:text-slate-300">
                  {@confirmed}/{@total_checks} confirmed
                </span>
              </:actions>

              <div class="mb-2.5 h-1.5 overflow-hidden rounded-full bg-slate-100 dark:bg-slate-800">
                <div
                  class="h-full rounded-full bg-gradient-to-r from-emerald-400 to-emerald-600 transition-all"
                  style={"width: #{@check_pct}%"}
                >
                </div>
              </div>

              <ul class="divide-y divide-slate-100 dark:divide-slate-800">
                <li :for={c <- @checks} class="flex items-center justify-between gap-2 py-1.5">
                  <span class="text-[12px] text-slate-700 dark:text-slate-300">{c.label}</span>
                  <.check_pill state={c.state} />
                </li>
              </ul>
            </.result_panel>

            <.result_panel title="Environment videos" icon="hero-video-camera">
              <:actions>
                <span class="text-[11px] font-semibold text-slate-600 dark:text-slate-300">
                  {length(@videos)} {if length(@videos) == 1, do: "video", else: "videos"}
                </span>
              </:actions>

              <div
                :if={@videos == []}
                class="flex h-28 flex-col items-center justify-center gap-1.5 rounded-lg border border-dashed border-slate-300 bg-slate-50 text-[12px] text-slate-400 dark:border-slate-700 dark:bg-slate-950"
              >
                <.icon name="hero-video-camera-slash" class="h-6 w-6 text-slate-300 dark:text-slate-600" />
                No environment video recorded
              </div>

              <div :if={@videos != []} id="env-videos" class="grid grid-cols-1 gap-2.5 sm:grid-cols-2 lg:grid-cols-1 xl:grid-cols-2">
                <div :for={{video, idx} <- Enum.with_index(@videos, 1)} id={"env-video-#{video.id}"} class="space-y-1">
                  <div class="overflow-hidden rounded-lg bg-black ring-1 ring-slate-200 dark:ring-slate-800">
                    <%!-- onplay pauses any other video in the modal, so only one plays at a time --%>
                    <video
                      controls
                      playsinline
                      preload="metadata"
                      src={video.url <> "#t=0.1"}
                      onplay="document.querySelectorAll('#env-videos video').forEach(v => { if (v !== this) v.pause() })"
                      class="aspect-video w-full object-contain"
                    >
                      Your browser can't play this video.
                    </video>
                  </div>
                  <div class="flex items-center justify-between px-0.5">
                    <span class="text-[11px] font-semibold text-slate-700 dark:text-slate-200">Video {idx}</span>
                    <a
                      href={video.url}
                      target="_blank"
                      rel="noopener"
                      class="inline-flex items-center gap-1 text-[11px] font-medium text-emerald-600 hover:text-emerald-500 dark:text-emerald-400"
                    >
                      Open
                      <.icon name="hero-arrow-top-right-on-square" class="h-3 w-3" />
                    </a>
                  </div>
                </div>
              </div>
            </.result_panel>
          </div>

          <%!-- Right: figures --%>
          <div class="space-y-4 lg:col-span-3">
            <div class="flex flex-wrap gap-1.5">
              <.status_badge label="Presiding officer signed" ok={@record[:presiding_officer_signed]} />
              <.status_badge label="Agent signatures present" ok={@record[:agent_signatures_present]} />
              <.status_badge label="Result sheet complete" ok={@record[:result_sheet_complete]} />
            </div>

            <div class="grid grid-cols-2 gap-2 sm:grid-cols-4">
              <.stat label="Registered" value={@record[:registered_voters]} icon="hero-user-group" tone="slate" />
              <.stat label="Accredited" value={@record[:accredited_voters]} icon="hero-identification" tone="sky" />
              <.stat label="Ballots issued" value={@record[:ballot_papers_issued]} icon="hero-ticket" tone="violet" />
              <.stat label="Unused ballots" value={@record[:unused_ballot_papers]} icon="hero-archive-box" tone="slate" />
              <.stat label="Spoiled" value={@record[:spoiled_ballots]} icon="hero-exclamation-triangle" tone="amber" />
              <.stat label="Rejected" value={@record[:rejected_votes]} icon="hero-no-symbol" tone="rose" />
              <.stat label="Valid votes" value={@record[:valid_votes]} icon="hero-check-badge" tone="emerald" />
              <.stat label="Total cast" value={@record[:total_votes_cast]} icon="hero-inbox-stack" tone="slate" />
            </div>

            <div class="flex items-center justify-between rounded-xl bg-gradient-to-r from-emerald-600 to-emerald-500 px-4 py-2.5 text-white shadow-md shadow-emerald-600/20">
              <div>
                <p class="text-[10px] font-semibold uppercase tracking-wider text-emerald-100">Total votes cast</p>
                <p class="text-xl font-extrabold leading-tight tracking-tight">{format_number(@record[:total_votes_cast])}</p>
              </div>
              <div class="flex h-9 w-9 items-center justify-center rounded-xl bg-white/15 ring-1 ring-inset ring-white/25">
                <.icon name="hero-chart-bar" class="h-5 w-5" />
              </div>
            </div>

            <.result_panel title="Party results" icon="hero-chart-bar-square">
              <div :if={@parties.shown == []} class="py-4 text-center text-[12px] text-slate-400">
                No party votes recorded.
              </div>

              <div class="space-y-2">
                <div :for={{{party, votes, pct}, idx} <- Enum.with_index(@parties.shown, 1)} class="flex items-center gap-2">
                  <span class={[
                    "flex h-5 w-5 shrink-0 items-center justify-center rounded-full text-[10px] font-bold",
                    party == @parties.leader && "bg-emerald-100 text-emerald-700 dark:bg-emerald-500/20 dark:text-emerald-300",
                    party != @parties.leader && "bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400"
                  ]}>
                    {idx}
                  </span>
                  <span class="w-11 shrink-0 text-[12px] font-bold text-slate-800 dark:text-slate-100">{party}</span>
                  <div class="h-5 flex-1 overflow-hidden rounded-md bg-slate-100 dark:bg-slate-800">
                    <div
                      class={[
                        "h-full rounded-md transition-all",
                        party == @parties.leader && "bg-gradient-to-r from-emerald-500 to-emerald-400",
                        party != @parties.leader && "bg-gradient-to-r from-slate-400 to-slate-300 dark:from-slate-600 dark:to-slate-500"
                      ]}
                      style={"width: #{max(pct, 4)}%"}
                    >
                    </div>
                  </div>
                  <span class="w-14 shrink-0 text-right font-mono text-[12px] font-semibold text-slate-700 dark:text-slate-200">
                    {format_number(votes)}
                  </span>
                </div>
              </div>

              <p :if={@parties.zero_count > 0} class="mt-3 text-[11px] text-slate-400 dark:text-slate-500">
                + {@parties.zero_count} other {if @parties.zero_count == 1, do: "party", else: "parties"} with 0 votes
              </p>
            </.result_panel>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Components
  # ---------------------------------------------------------------------------

  attr :title, :string, required: true
  attr :icon, :string, default: nil
  slot :actions
  slot :inner_block, required: true

  defp result_panel(assigns) do
    ~H"""
    <section class="rounded-xl border border-slate-200 bg-white p-3.5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
      <div class="mb-2.5 flex items-center justify-between gap-2">
        <h4 class="flex items-center gap-1.5 text-[12px] font-semibold text-slate-800 dark:text-slate-100">
          <span :if={@icon} class="flex h-6 w-6 items-center justify-center rounded-md bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400">
            <.icon name={@icon} class="h-3.5 w-3.5" />
          </span>
          {@title}
        </h4>
        {render_slot(@actions)}
      </div>
      {render_slot(@inner_block)}
    </section>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, default: nil
  attr :icon, :string, required: true
  attr :mono, :boolean, default: false

  defp meta_item(assigns) do
    ~H"""
    <div class="flex items-center gap-2">
      <div class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-white text-slate-400 ring-1 ring-slate-200 dark:bg-slate-900 dark:text-slate-500 dark:ring-slate-800">
        <.icon name={@icon} class="h-4 w-4" />
      </div>
      <div class="min-w-0 leading-tight">
        <p class="text-[9px] font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500">{@label}</p>
        <p class={[
          "truncate text-[12px] font-semibold text-slate-800 dark:text-slate-100",
          @mono && "font-mono"
        ]}>
          {if @value in [nil, ""], do: "—", else: @value}
        </p>
      </div>
    </div>
    """
  end

  attr :upload_url, :any, required: true
  attr :polling_unit, :any, required: true

  defp result_photo(assigns) do
    ~H"""
    <a
      :if={@upload_url}
      href={@upload_url}
      target="_blank"
      rel="noopener"
      class="group relative block overflow-hidden rounded-lg border border-slate-200 bg-slate-50 dark:border-slate-800 dark:bg-slate-950"
    >
      <img
        src={@upload_url}
        alt={"Result sheet - #{@polling_unit}"}
        class="h-auto max-h-[38vh] w-full object-contain"
      />
      <div class="absolute inset-0 flex items-center justify-center bg-slate-900/0 opacity-0 transition group-hover:bg-slate-900/40 group-hover:opacity-100">
        <span class="inline-flex items-center gap-1 rounded-full bg-white/95 px-2.5 py-1 text-[11px] font-semibold text-slate-800 shadow">
          <.icon name="hero-magnifying-glass-plus" class="h-3.5 w-3.5" />
          View full size
        </span>
      </div>
    </a>
    <div
      :if={!@upload_url}
      class="flex h-36 flex-col items-center justify-center gap-1.5 rounded-lg border border-dashed border-slate-300 bg-slate-50 text-[12px] text-slate-400 dark:border-slate-700 dark:bg-slate-950"
    >
      <.icon name="hero-photo" class="h-6 w-6 text-slate-300 dark:text-slate-600" />
      No result sheet image uploaded
    </div>
    """
  end

  attr :label, :string, required: true
  attr :ok, :any, required: true

  defp status_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[11px] font-medium ring-1 ring-inset",
      @ok && "bg-emerald-50 text-emerald-700 ring-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-300 dark:ring-emerald-500/20",
      !@ok && "bg-rose-50 text-rose-700 ring-rose-200 dark:bg-rose-500/10 dark:text-rose-300 dark:ring-rose-500/20"
    ]}>
      <.icon name={if @ok, do: "hero-check-circle", else: "hero-x-circle"} class="h-3.5 w-3.5" />
      {@label}
    </span>
    """
  end

  attr :state, :atom, required: true

  defp check_pill(assigns) do
    ~H"""
    <span class={[
      "inline-flex shrink-0 items-center gap-0.5 rounded-full px-2 py-0.5 text-[10px] font-semibold",
      @state == :yes && "bg-emerald-100 text-emerald-700 dark:bg-emerald-500/15 dark:text-emerald-300",
      @state == :no && "bg-rose-100 text-rose-700 dark:bg-rose-500/15 dark:text-rose-300",
      @state == :unknown && "bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400"
    ]}>
      <.icon name={pill_icon(@state)} class="h-3 w-3" />
      {pill_label(@state)}
    </span>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true
  attr :icon, :string, required: true
  attr :tone, :string, default: "slate"

  defp stat(assigns) do
    ~H"""
    <div class="rounded-xl border border-slate-200 bg-white p-2.5 shadow-sm transition hover:shadow-md dark:border-slate-800 dark:bg-slate-900">
      <div class="flex items-center justify-between">
        <p class="text-[10px] font-medium text-slate-500 dark:text-slate-400">{@label}</p>
        <span class={["flex h-6 w-6 items-center justify-center rounded-md", tone_classes(@tone)]}>
          <.icon name={@icon} class="h-3.5 w-3.5" />
        </span>
      </div>
      <p class="mt-1 text-base font-bold tracking-tight text-slate-900 dark:text-slate-100">
        {format_number(@value)}
      </p>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp tone_classes("emerald"), do: "bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-400"
  defp tone_classes("sky"), do: "bg-sky-50 text-sky-600 dark:bg-sky-500/10 dark:text-sky-400"
  defp tone_classes("violet"), do: "bg-violet-50 text-violet-600 dark:bg-violet-500/10 dark:text-violet-400"
  defp tone_classes("amber"), do: "bg-amber-50 text-amber-600 dark:bg-amber-500/10 dark:text-amber-400"
  defp tone_classes("rose"), do: "bg-rose-50 text-rose-600 dark:bg-rose-500/10 dark:text-rose-400"
  defp tone_classes(_), do: "bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400"

  defp pill_icon(:yes), do: "hero-check-circle"
  defp pill_icon(:no), do: "hero-x-circle"
  defp pill_icon(_), do: "hero-minus-circle"

  defp pill_label(:yes), do: "Yes"
  defp pill_label(:no), do: "No"
  defp pill_label(_), do: "No answer"

  # Only built when the record carries `variables` (EC8A previews).
  defp build_checks(variables) when is_map(variables) and map_size(variables) > 0 do
    Enum.map(@checks, fn {key, label} ->
      %{label: label, state: check_state(Map.get(variables, key))}
    end)
  end

  defp build_checks(_), do: []

  defp check_state(v) when v in [true, "true", 1, "1"], do: :yes
  defp check_state(v) when v in [false, "false", 0, "0"], do: :no
  defp check_state(_), do: :unknown

  # Sorts party_results descending, drops zero-vote parties from the
  # chart (counted separately instead), and computes each bar's width
  # as a percentage of the leading party's vote count.
  defp top_parties(party_results) when not is_map(party_results),
    do: %{shown: [], leader: nil, zero_count: 0}

  defp top_parties(party_results) do
    sorted =
      party_results
      |> Enum.map(fn {party, votes} -> {party, to_number(votes)} end)
      |> Enum.sort_by(fn {_party, votes} -> votes end, :desc)

    {with_votes, zero_votes} = Enum.split_with(sorted, fn {_party, votes} -> votes > 0 end)

    max_votes =
      case with_votes do
        [{_party, top} | _] -> top
        [] -> 0
      end

    shown =
      Enum.map(with_votes, fn {party, votes} ->
        pct = if max_votes > 0, do: votes / max_votes * 100, else: 0
        {party, votes, pct}
      end)

    leader =
      case shown do
        [{party, _votes, _pct} | _] -> party
        [] -> nil
      end

    %{shown: shown, leader: leader, zero_count: length(zero_votes)}
  end

  defp to_number(v) when is_integer(v) or is_float(v), do: v

  defp to_number(v) when is_binary(v) do
    case Integer.parse(v) do
      {n, _} -> n
      :error -> 0
    end
  end

  defp to_number(_), do: 0

  # 12345 -> "12,345"; nil -> "0"
  defp format_number(nil), do: "0"

  defp format_number(n) when is_integer(n) do
    n
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end

  defp format_number(n) when is_float(n), do: n |> round() |> format_number()
  defp format_number(n), do: to_string(n)

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

  # "presidential_election" -> "Presidential Election"
  defp humanize(nil), do: ""

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace(["_", "-"], " ")
    |> String.split(" ", trim: true)
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp format_datetime(nil), do: nil

  defp format_datetime(%mod{} = dt) when mod in [DateTime, NaiveDateTime],
    do: Calendar.strftime(dt, "%b %-d, %Y, %-I:%M %p")

  defp format_datetime(_), do: nil
end
