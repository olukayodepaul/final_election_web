defmodule WebApiElectionWeb.Admin.SwitchDashboardLive do
  @moduledoc """
  LiveView conversion of the static "P — Admin Panel" mockup.
  """
  use WebApiElectionWeb, :live_view
  alias Phoenix.LiveView.JS
  alias WebApiElection.SupervisorMonitorQuery
  alias WebApiElection.Reporting.PollingUnitReport
  alias WebApiElection.Reporting.PollingSecuriyReport
  alias WebApiElection.Reporting.WardSecurityReport
  alias WebApiElection.Reporting.PartyAgentReport
  alias WebApiElection.Reporting.ElectionResultReportQuery
  alias WebApiElection.Reporting.ElectionCollationQuery
  alias WebApiElection.Reporting.ElectionResultReport
  alias WebApiElection.Assignments.SupervisorWardAssignment
  alias WebApiElection.Assignments.FieldOfficerAssignment

  import WebApiElectionWeb.Admin.SwitchDashboardLive.Components.DashboardPage
  import WebApiElectionWeb.Admin.SwitchDashboardLive.Components.PartiesPage
  import WebApiElectionWeb.Admin.SwitchDashboardLive.Components.LivePage
  import WebApiElectionWeb.Admin.SwitchDashboardLive.Components.CdrsPage
  import WebApiElectionWeb.Admin.SwitchDashboardLive.Components.FieldOfficersPage
  import WebApiElectionWeb.Admin.SwitchDashboardLive.Components.PlaceholderPage
  import WebApiElectionWeb.Admin.SwitchDashboardLive.Components.CdrModal
  import WebApiElectionWeb.Admin.SwitchDashboardLive.Components.LiveModal
  import WebApiElectionWeb.Admin.SwitchDashboardLive.Components.ElectionResultModal
  import WebApiElectionWeb.Admin.SwitchDashboardLive.Components.Elections.PresidentialEC8APage

  import WebApiElectionWeb.Admin.SwitchDashboardLive.Components.Elections.PresidentialPage
  import WebApiElectionWeb.Admin.SwitchDashboardLive.Components.Elections.SenatorialPage
  import WebApiElectionWeb.Admin.SwitchDashboardLive.Components.Elections.LgPage
  import WebApiElectionWeb.Admin.SwitchDashboardLive.Components.Elections.RepsPage
  import WebApiElectionWeb.Admin.SwitchDashboardLive.Components.Elections.AssemplyPage
  import WebApiElectionWeb.Admin.SwitchDashboardLive.Components.GovernorshipPage

  # TODO: replace with real per-user SIP credentials once provisioned.
  @sip_shared_password "bashAqwe"

  @nav_pages [
    {"dashboard", "Dashboard", "hero-squares-2x2"},
    {"parties", "Political Parties", "hero-flag"},
    {"live", "Live Monitor", "hero-signal"},
    {"cdrs", "CDRs", "hero-phone-arrow-up-right"},
    {"routes", "Pu Locations", "hero-arrows-right-left"}
  ]

  # Hardcoded: the elections list is no longer fetched from the DB.
  @elections [%{id: 1, name: "Presidential"}]

  @ec8a_nav_items [
     {"ec8a-1", "Election Form", "hero-document-chart-bar"}
  ]

  @implemented_pages ~w(dashboard parties live cdrs election-result-view)

  @cdrs [
    %{
      time: "9:33:56 AM",
      call_id: "e5d1ac95-8949…",
      from: "Rhemylove Rhemylove <+201158",
      to: "+2348032575801",
      carrier: "MTN (visafone)",
      cc: "NG",
      dur: "2m 30s",
      pdd: 4600,
      trunk: "mfbcommunications.ng",
      switch: "FS2USEAST1",
      disposition: "NORMAL_CLEARING",
      mos: "4.49",
      status: "OK"
    },
    %{
      time: "9:20:54 AM",
      call_id: "e5d1ac8c-85a7…",
      from: "Pro Mise <+971521009806>",
      to: "+2348105747191",
      carrier: "MTN (visafone)",
      cc: "NG",
      dur: "0s",
      pdd: 12_780,
      trunk: "mfbcommunications.ng",
      switch: "FS2USEAST1",
      disposition: "NORMAL_CLEARING",
      mos: "4.47",
      status: "BUSY"
    },
    %{
      time: "9:20:25 AM",
      call_id: "e5d1aca5-9f92…",
      from: "<+2348106366189>",
      to: "+2347025314355",
      carrier: "MTN (visafone)",
      cc: "NG",
      dur: "7s",
      pdd: 0,
      trunk: "—",
      switch: "FS1USEAST1",
      disposition: "NO_BALANCE",
      mos: "4.50",
      status: "OK"
    },
    %{
      time: "9:20:18 AM",
      call_id: "e5d1ac2c-c9a8…",
      from: "Pro Mise <+971521009806>",
      to: "+2348166100722",
      carrier: "MTN (visafone)",
      cc: "NG",
      dur: "0s",
      pdd: 12_640,
      trunk: "idtexpress.com-platinum",
      switch: "FS1USEAST1",
      disposition: "NORMAL_UNSPECIFIED",
      mos: "4.48",
      status: "FAIL"
    },
    %{
      time: "9:20:02 AM",
      call_id: "e5d1ac33-a054…",
      from: "Pro Mise <+971521009806>",
      to: "+2347018079087",
      carrier: "Airtel Nigeria",
      cc: "NG",
      dur: "0s",
      pdd: 2400,
      trunk: "idtexpress.com-platinum",
      switch: "FS2USEAST1",
      disposition: "NORMAL_UNSPECIFIED",
      mos: "4.50",
      status: "FAIL"
    },
    %{
      time: "9:19:47 AM",
      call_id: "e5d1ac1d-726a…",
      from: "Pro Mise <+971521009806>",
      to: "+2348166100722",
      carrier: "MTN (visafone)",
      cc: "NG",
      dur: "0s",
      pdd: 2200,
      trunk: "mfbcommunications.ng",
      switch: "FS1USEAST1",
      disposition: "NORMAL_CLEARING",
      mos: "4.46",
      status: "BUSY"
    },
    %{
      time: "9:11:46 AM",
      call_id: "e5d1ace9-afad…",
      from: "Ikechukwu Unoaha <+234806865",
      to: "+2349162735025",
      carrier: "MTN (visafone)",
      cc: "NG",
      dur: "10s",
      pdd: 3660,
      trunk: "mfbcommunications.ng",
      switch: "FS1USEAST1",
      disposition: "NORMAL_CLEARING",
      mos: "4.50",
      status: "OK"
    },
    %{
      time: "8:39:54 AM",
      call_id: "e5d1ac82-15c8…",
      from: "Nosakhare ehouwa Michael eho",
      to: "+2349067427103",
      carrier: "MTN (visafone)",
      cc: "NG",
      dur: "13m 37s",
      pdd: 3700,
      trunk: "mfbcommunications.ng",
      switch: "FS2USEAST1",
      disposition: "NORMAL_CLEARING",
      mos: "4.50",
      status: "OK"
    }
  ]

  @parties [
    %{name: "All Progressives Congress", acronym: "APC", color: "bg-sky-500", head_office: "40 Blantyre Street, Wuse II, Abuja, FCT"},
    %{name: "Peoples Democratic Party", acronym: "PDP", color: "bg-emerald-600", head_office: "16 Umaru Musa Yar'Adua Way, Wuse Zone 5, Abuja, FCT"},
    %{name: "Labour Party", acronym: "LP", color: "bg-rose-600", head_office: "11 Zambezi Crescent, Maitama, Abuja, FCT"},
    %{name: "New Nigeria Peoples Party", acronym: "NNPP", color: "bg-amber-500", head_office: "11 Malabo Street, Wuse Zone 3, Abuja, FCT"},
    %{name: "All Progressives Grand Alliance", acronym: "APGA", color: "bg-indigo-500", head_office: "1 Ziks Avenue, Awka, Anambra State"},
    %{name: "Social Democratic Party", acronym: "SDP", color: "bg-orange-500", head_office: "11 Kumba Street, Wuse II, Abuja, FCT"},
    %{name: "African Democratic Congress", acronym: "ADC", color: "bg-teal-600", head_office: "Plot 1099, First Avenue, Gwarinpa, Abuja, FCT"},
    %{name: "Young Progressives Party", acronym: "YPP", color: "bg-fuchsia-600", head_office: "6 Oyinkan Abayomi Drive, Ikoyi, Lagos State"}
  ]

  @candidates [
    %{name: "Candidate A", party: "APC", color: "bg-sky-500", votes: "14.2M", pct: 36},
    %{name: "Candidate B", party: "PDP", color: "bg-emerald-500", votes: "12.9M", pct: 32},
    %{name: "Candidate C", party: "LP", color: "bg-rose-500", votes: "8.1M", pct: 20},
    %{name: "Candidate D", party: "NNPP", color: "bg-amber-500", votes: "4.6M", pct: 12}
  ]

  @state_results [
    %{state: "Lagos", party: "APC", votes: "1.82M", turnout: "38.4%", status: "Declared"},
    %{state: "Kano", party: "NNPP", votes: "1.64M", turnout: "41.0%", status: "Declared"},
    %{state: "Rivers", party: "PDP", votes: "980K", turnout: "35.2%", status: "Declared"},
    %{state: "Kaduna", party: "APC", votes: "870K", turnout: "33.7%", status: "Declared"},
    %{state: "Oyo", party: "PDP", votes: "790K", turnout: "36.9%", status: "Declared"},
    %{state: "FCT Abuja", party: "LP", votes: "640K", turnout: "44.1%", status: "Declared"},
    %{state: "Anambra", party: "LP", votes: "610K", turnout: "39.5%", status: "Declared"},
    %{state: "Delta", party: "PDP", votes: "560K", turnout: "31.8%", status: "Collating"},
    %{state: "Ogun", party: "APC", votes: "520K", turnout: "34.0%", status: "Declared"},
    %{state: "Enugu", party: "LP", votes: "480K", turnout: "37.3%", status: "Collating"},
    %{state: "Borno", party: "APC", votes: "410K", turnout: "29.6%", status: "Collating"},
    %{state: "Plateau", party: "PDP", votes: "380K", turnout: "33.1%", status: "Declared"}
  ]

  # ---------------------------------------------------------------------------
  # Mount / Params
  # ---------------------------------------------------------------------------

  @impl true
  def mount(_params, session, socket) do
    supervisor_id = session["user_id"] || 1

    socket =
      if connected?(socket) do
        Phoenix.PubSub.subscribe(WebApiElection.PubSub, "inec_official:#{supervisor_id}")

        # make sure we change this to user id to receive sip call from the client.
        push_event(socket, "sip_credentials", %{
          extension: 1001,
          password: @sip_shared_password
        })
      else
        socket
      end

    socket =
      socket
      |> assign(:nav_pages, @nav_pages)
      |> assign(:supervisor_id, supervisor_id)
      |> assign(:selected_live_officer, nil)
      |> assign(:party_agent_report, nil)
      |> assign(:loading_party_agent, false)
      |> assign(:ec8a_nav_items, @ec8a_nav_items)
      |> assign(:elections_result_page, @elections)
      |> assign(:implemented_pages, @implemented_pages)
      |> assign(:today_label, Calendar.strftime(Date.utc_today(), "%A, %B %-d, %Y"))
      |> assign(:sidebar_collapsed, false)
      |> assign(:state_filter, "")
      |> assign(:selected_cdr_index, nil)
      |> assign(:messages, [])
      |> assign(:presiding_officer_report, nil)
      |> assign(:loading_presiding_officer, false)
      |> assign(:pu_security_report, nil)
      |> assign(:loading_pu_security, false)
      |> assign(:ward_security_report, nil)
      |> assign(:loading_ward_security, false)
      |> assign(:selected_election_result, nil)
      |> assign(:current_election_id, nil)
      |> assign(:current_election_name, nil)
      |> assign(:current_ec8a_election_id, nil)
      |> assign(:current_ec8a_election_name, nil)
      |> assign(:collation_election_id, nil)
      |> assign(:collation_ward, nil)

    {:ok, socket}
  end

  @impl true
  def handle_info({:inec_official, %WebApiElection.Reporting.Message{} = message}, socket) do
    {:noreply, append_message(socket, message)}
  end

  @impl true
  def handle_info({:inec_official, report}, socket) do
    {:noreply, socket |> patch_field_officer(report) |> refresh_open_report(report)}
  end

  # Only EC8A uploads belong on the EC8A page; other forms are ignored.
  def handle_info({:election_form_uploaded, %{election_form: "ec8a"} = summary}, socket) do
    {:noreply, add_ec8a_report(socket, summary)}
  end

  def handle_info({:election_form_uploaded, _other_form}, socket), do: {:noreply, socket}

  defp patch_field_officer(socket, report) do
    case socket.assigns[:field_officer] do
      %Phoenix.LiveView.AsyncResult{ok?: true, result: officers} = async ->
        patch = report_patch_fields(report)

        updated_officers =
          Enum.map(officers, fn officer ->
            if officer.user_id == report.user_id do
              Map.merge(officer, patch)
            else
              officer
            end
          end)

        assign(socket, :field_officer, %{async | result: updated_officers})

      _not_loaded_yet ->
        socket
    end
  end

  # Adds the new upload to the already-loaded :ec8a_reports map
  # (%{user_id => [report, ...]}, newest first). Removing by id first means
  # a retried/duplicate send never shows up twice.
  defp add_ec8a_report(socket, summary) do
    case socket.assigns[:ec8a_reports] do
      %Phoenix.LiveView.AsyncResult{ok?: true, result: by_user} = async when is_map(by_user) ->
        updated =
          Map.update(by_user, summary.user_id, [summary], fn list ->
            [summary | Enum.reject(list, &(&1.id == summary.id))]
          end)

        assign(socket, :ec8a_reports, %{async | result: updated})

      _not_loaded_yet ->
        socket
    end
  end

  defp append_message(socket, message) do
    officer = socket.assigns.selected_live_officer

    if officer && message.user_id == officer.user_id do
      bubble = to_chat_bubble(message)
      assign(socket, :messages, socket.assigns.messages ++ [bubble])
    else
      socket
    end
  end

  defp to_chat_bubble(%WebApiElection.Reporting.Message{} = message) do
    %{
      from: if(message.owner == 1, do: :admin, else: :officer),
      body: message.payload,
      type: message.payload_type,
      time: Calendar.strftime(message.created_at, "%-I:%M %p")
    }
  end

  defp report_patch_fields(%WebApiElection.Reporting.PollingUnitReport{payload: payload}) do

    elec_outcome =
      case payload["electionOutcome"] do
        1 -> "Ongoing"
        2 -> "Collation"
        3 -> "Concluded"
        4 -> "Cancelled"
        5 -> "Disrupted"
        _ -> ""
      end

    acr_method =
      case payload["accreditationMethod"] do
        1 -> "Manual"
        2 -> "Bvas"
        _ -> ""
      end

    %{}
    |> maybe_put(:inec_ar_time, payload["arrivalTime"])
    |> maybe_put(:official_no, payload["numberOfInecOfficial"])
    |> maybe_put(:is_bvas_available, payload["isBvnMachineAvail"])
    |> maybe_put(:is_bvas_working, payload["isBvbDeviceGoodCond"])
    |> maybe_put(:has_accr_commence, payload["hasAccredCommence"])
    |> maybe_put(:has_voting_commence, payload["hasVolingCommence"])
    |> maybe_put(:is_voters_verify_with_bvas, acr_method)
    |> maybe_put(:accr_started_at, payload["accrStartedAt"])
    |> maybe_put(:voting_started_at, payload["voteStart"])
    |> maybe_put(:is_conclusive, elec_outcome)
    |> maybe_put(:is_conclusive_time, payload["elecConClusive"])
    |> maybe_put(:is_voters_verify_with_bvas_time, payload["isVotersVerifyWithBvasTime"])
    |> maybe_put(:is_bvas_working_time, payload["BvasFunc"])
    |> maybe_put(:is_bvas_available_time, payload["Bavai"])
    |> maybe_put(:inec_ar_time, payload["InecRr"])
  end

  defp report_patch_fields(%WebApiElection.Reporting.PollingSecuriyReport{payload: payload}) do
    %{}
    |> maybe_put(:security_present, payload["securityPresence"])
    |> maybe_put(:security_present_time, payload["securityPresentTime"])
  end

  defp report_patch_fields(%WebApiElection.Reporting.WardSecurityReport{payload: payload}) do
    party_agent_movement =
      case String.upcase(to_string(payload["partyAgentMovement"])) do
        "ARRIVED" -> "ARRIVED COLLATION CENTER"
        "DEPARTED" -> "DEPARTED PU"
        _ -> nil
      end

    %{}
    |> maybe_put(:is_pu_officer_at_collation_center, party_agent_movement)
    |> maybe_put(:is_pu_officer_at_collation_center_ar_time, payload["collationArTime"])
    |> maybe_put(:has_proceed_to_ward, payload["collationStatus"])
    |> maybe_put(:collation_status_time, payload["collationStatusTime"])
  end

  defp report_patch_fields(%WebApiElection.Reporting.PartyAgentReport{payload: payload}) do
    agent_at_pu =
      case payload["agentClearance"] do
        1 -> "Cleared"
        2 -> "Not Cleared"
        _ -> ""
      end

    %{}
    |> maybe_put(:arrival_time, payload["agentArrivalTime"])
    |> maybe_put(:did_inec_clear_agent_time, payload["clearedTime"])
    |> maybe_put(:is_agent_at_polling_unit, payload["isAtAssignedUnit"])
    |> maybe_put(:did_inec_clear_agent, agent_at_pu)
  end

  defp report_patch_fields(_other), do: %{}

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  # Clears every cached report so a newly opened modal never shows the previous officer's data.
  defp reset_reports(socket) do
    socket
    |> assign(:presiding_officer_report, nil)
    |> assign(:pu_security_report, nil)
    |> assign(:ward_security_report, nil)
    |> assign(:party_agent_report, nil)
    |> assign(:loading_presiding_officer, false)
    |> assign(:loading_pu_security, false)
    |> assign(:loading_ward_security, false)
    |> assign(:loading_party_agent, false)
  end

  # If this officer's modal is open, re-read the matching report from the DB.
  defp refresh_open_report(socket, report) do
    officer = socket.assigns.selected_live_officer
    user_id = Map.get(report, :user_id)

    if officer && user_id == officer.user_id do
      case report do
        %PollingUnitReport{} ->
          assign(socket, :presiding_officer_report, WebApiElection.Repo.get_by(PollingUnitReport, user_id: user_id))

        %PollingSecuriyReport{} ->
          assign(socket, :pu_security_report, WebApiElection.Repo.get_by(PollingSecuriyReport, user_id: user_id))

        %WardSecurityReport{} ->
          assign(socket, :ward_security_report, WebApiElection.Repo.get_by(WardSecurityReport, user_id: user_id))

        %PartyAgentReport{} ->
          assign(socket, :party_agent_report, WebApiElection.Repo.get_by(PartyAgentReport, user_id: user_id))

        _ ->
          socket
      end
    else
      socket
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    page = params["page"] || "dashboard"

    socket =
      socket
      |> assign(:page, page)
      |> load_page_data(page)

    {:noreply, socket}
  end

  # ---------------------------------------------------------------------------
  # Lazy Loading Page Context Helpers
  # (all load_page_data/2 clauses are grouped together; catch-all is last)
  # ---------------------------------------------------------------------------

  defp load_page_data(socket, "dashboard") do
    load_field_officer_async(socket)
  end

  defp load_page_data(socket, "parties") do
    assign(socket, parties: @parties)
  end

  defp load_page_data(socket, "live") do
    load_field_officer_async(socket)
  end

  defp load_page_data(socket, "cdrs") do
    assign(socket, cdrs: @cdrs)
  end

  defp load_page_data(socket, "field_officers") do
    supervisor_id = socket.assigns.supervisor_id

    if Map.has_key?(socket.assigns, :field_officer_states) do
      socket
    else
      assign_async(socket, :field_officer_states, fn ->
        states = SupervisorMonitorQuery.get_field_officer_states(supervisor_id)
        {:ok, %{field_officer_states: states}}
      end)
    end
  end

  defp load_page_data(socket, "election-result-view") do
    if Map.has_key?(socket.assigns, :election_result_view) do
      socket
    else
      supervisor_id = socket.assigns.supervisor_id

      assign_async(socket, [:election_result_view, :election_result_stats], fn ->
        results = ElectionResultReportQuery.fetch_results_for_supervisor(supervisor_id)
        expected = ElectionResultReportQuery.count_expected_for_supervisor(supervisor_id)

        uploaded = length(results)
        lga_count = results |> Enum.map(& &1.lg_code) |> Enum.uniq() |> length()
        last_upload = results |> Enum.map(& &1.created_at) |> Enum.max(DateTime, fn -> nil end)

        stats = %{
          uploaded: uploaded,
          expected: expected,
          percentage: if(expected > 0, do: Float.round(uploaded / expected * 100, 2), else: 0.0),
          lga_count: lga_count,
          last_upload_at: last_upload
        }

        {:ok, %{election_result_view: results, election_result_stats: stats}}
      end)
    end
  end

  # EC8A page: list of field officers assigned to this supervisor's wards,
  # plus every result upload (election_result_report) for those officers.
  # Loads :ec8a_officers AND :ec8a_reports in one async task.
  defp load_page_data(socket, "ec8a-" <> id) do
    case Integer.parse(id) do
      {election_id, ""} ->
        election = Enum.find(socket.assigns.elections_result_page, &(&1.id == election_id))
        supervisor_id = socket.assigns.supervisor_id

        socket
        |> assign(:current_ec8a_election_id, election_id)
        |> assign(:current_ec8a_election_name, election && election.name)
        |> assign_async([:ec8a_officers, :ec8a_reports], fn ->
          assignments = SupervisorWardAssignment.active_for_supervisor(supervisor_id)
          officers = FieldOfficerAssignment.active_for_wards(assignments)

          # %{user_id => [%{id, user_id, pu_id, election_name, created_at}, ...]}
          reports =
            officers
            |> Enum.map(& &1.user_id)
            |> Enum.uniq()
            |> ElectionResultReport.list_for_users()

          {:ok, %{ec8a_officers: officers, ec8a_reports: reports}}
        end)

      _ ->
        socket
    end
  end

  defp load_page_data(socket, "election-" <> id) do
    case Integer.parse(id) do
      {election_id, ""} ->
        election = Enum.find(socket.assigns.elections_result_page, &(&1.id == election_id))
        manager_id = socket.assigns.supervisor_id

        socket =
          socket
          |> assign(:current_election_id, election_id)
          |> assign(:current_election_name, election && election.name)
          # still used by the other (mock) election pages
          |> assign(:candidates, @candidates)
          |> assign(:state_results, @state_results)

        if socket.assigns.collation_election_id == election_id do
          socket
        else
          socket
          |> assign(:collation_election_id, election_id)
          |> assign(:collation_ward, nil)
          |> assign_async(:collation, fn ->
            {:ok, %{collation: ElectionCollationQuery.load(manager_id, election_id)}}
          end)
        end

      _ ->
        socket
    end
  end

  # Unknown pages (e.g. "routes") fall through to the placeholder instead of crashing.
  defp load_page_data(socket, _other), do: socket

  defp load_field_officer_async(socket) do
    supervisor_id = socket.assigns.supervisor_id

    assign_async(socket, :field_officer, fn ->
      states = SupervisorMonitorQuery.get_field_officer_states(supervisor_id)
      {:ok, %{field_officer: states}}
    end)
  end

  defp ec8a_page?("ec8a-" <> rest) do
    case Integer.parse(rest) do
      {_int, ""} -> true
      _ -> false
    end
  end

  defp ec8a_page?(_), do: false

  defp election_type_page?("election-" <> rest) when rest != "result-view" do
    case Integer.parse(rest) do
      {_int, ""} -> true
      _ -> false
    end
  end

  defp election_type_page?(_), do: false

  defp to_int(id) when is_integer(id), do: id
  defp to_int(id) when is_binary(id), do: String.to_integer(id)

  # True only if `report_id` is one of the uploads already loaded for this supervisor's
  # officers. Stops a tampered "view_report" event from reading someone else's report.
  defp report_visible?(socket, report_id) do
    case socket.assigns[:ec8a_reports] do
      %Phoenix.LiveView.AsyncResult{ok?: true, result: by_user} when is_map(by_user) ->
        by_user
        |> Map.values()
        |> List.flatten()
        |> Enum.any?(&(&1.id == report_id))

      _ ->
        false
    end
  end

  # ---------------------------------------------------------------------------
  # Events
  # ---------------------------------------------------------------------------

  @impl true
  def handle_event("toggle-sidebar", _params, socket) do
    {:noreply, assign(socket, :sidebar_collapsed, !socket.assigns.sidebar_collapsed)}
  end

  def handle_event("filter-state", %{"value" => value}, socket) do
    {:noreply, assign(socket, :state_filter, value)}
  end

  def handle_event("open-cdr-modal", %{"index" => index}, socket) do
    {:noreply, assign(socket, :selected_cdr_index, String.to_integer(index))}
  end

  def handle_event("close-cdr-modal", _params, socket) do
    {:noreply, assign(socket, :selected_cdr_index, nil)}
  end

  def handle_event("open-live-modal", params, socket) do
    user_id = params["id"]

    officer =
      case socket.assigns.field_officer do
        %Phoenix.LiveView.AsyncResult{ok?: true, result: officers} ->
          Enum.find(officers, fn o -> to_string(o.user_id) == user_id end)

        _ ->
          nil
      end

    {:noreply, socket |> reset_reports() |> assign(:selected_live_officer, officer)}
  end

  def handle_event("close-live-modal", _params, socket) do
    {:noreply, socket |> reset_reports() |> assign(:selected_live_officer, nil)}
  end

  # Every fetch-* handler queries the DB on every click, so the panels always show the latest report.
  def handle_event("fetch-presiding-officer", %{"user_id" => user_id}, socket) do
    report = WebApiElection.Repo.get_by(PollingUnitReport, user_id: to_int(user_id))

    {:noreply,
     socket
     |> assign(:presiding_officer_report, report)
     |> assign(:loading_presiding_officer, false)}
  end

  def handle_event("fetch-pu-security", %{"user_id" => user_id}, socket) do
    report = WebApiElection.Repo.get_by(PollingSecuriyReport, user_id: to_int(user_id))

    {:noreply,
     socket
     |> assign(:pu_security_report, report)
     |> assign(:loading_pu_security, false)}
  end

  def handle_event("fetch-ward-security", %{"user_id" => user_id}, socket) do
    report = WebApiElection.Repo.get_by(WardSecurityReport, user_id: to_int(user_id))

    {:noreply,
     socket
     |> assign(:ward_security_report, report)
     |> assign(:loading_ward_security, false)}
  end

  def handle_event("fetch-party-agent", %{"user_id" => user_id}, socket) do
    report = WebApiElection.Repo.get_by(PartyAgentReport, user_id: to_int(user_id))

    {:noreply,
     socket
     |> assign(:party_agent_report, report)
     |> assign(:loading_party_agent, false)}
  end

  def handle_event("send-live-message", %{"body" => body}, socket) do
    officer = socket.assigns.selected_live_officer

    message = %{
      from: officer.supervisor_id,
      to: officer.field_officer_id,
      id: officer.user_id,
      pu_code: officer.pu_code,
      ward_code: officer.ward_code,
      lg_code: officer.lg_code,
      state_code: officer.state_code,
      message: body
    }

    WebApiElection.ExternalSocket.Connection.send_chat_message(message)

    bubble = %{from: :admin, body: body, type: "TEXT", time: Calendar.strftime(DateTime.utc_now(), "%-I:%M %p")}
    {:noreply, assign(socket, :messages, socket.assigns.messages ++ [bubble])}
  end

  def handle_event("open-election-result-modal", %{"user_id" => user_id}, socket) do
    user_id_int = to_int(user_id)

    record =
      case socket.assigns[:election_result_view] do
        %Phoenix.LiveView.AsyncResult{ok?: true, result: results} ->
          Enum.find(results, fn r -> r.user_id == user_id_int end)

        _ ->
          nil
      end

    {:noreply, assign(socket, :selected_election_result, record)}
  end

  def handle_event("close-election-result-modal", _params, socket) do
    {:noreply, assign(socket, :selected_election_result, nil)}
  end

  def handle_event("select-collation-ward", %{"ward_id" => id}, socket) do
    {:noreply, assign(socket, :collation_ward, to_int(id))}
  end

  def handle_event("clear-collation-ward", _params, socket) do
    {:noreply, assign(socket, :collation_ward, nil)}
  end

  # EC8A page: "View" button on an upload. Loads the full election_result_report and opens
  # the existing election_result_modal. Invalid or out-of-scope ids are ignored.
  def handle_event("view_report", %{"id" => id}, socket) do
    with {report_id, ""} <- Integer.parse(to_string(id)),
         true <- report_visible?(socket, report_id),
         %{} = record <- ElectionResultReport.get_for_preview(report_id) do
      {:noreply, assign(socket, :selected_election_result, record)}
    else
      _ -> {:noreply, socket}
    end
  end

  # ---------------------------------------------------------------------------
  # Render
  # ---------------------------------------------------------------------------

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen bg-gray-50 text-ink dark:bg-slate-950 dark:text-slate-100 transition-colors">
      <div id="sip-credentials-receiver" phx-hook="SipCredentials" style="display:none"></div>

      <!-- ============ SIDEBAR ============ -->
      <aside class={[
        "shrink-0 bg-white dark:bg-slate-950 border-r border-gray-200 dark:border-slate-800 flex flex-col justify-between transition-all duration-300 ease-in-out relative",
        @sidebar_collapsed && "w-16 px-2",
        !@sidebar_collapsed && "w-60 px-3"
      ]}>
        <div>
          <!-- Header / Brand -->
          <div class={[
            "flex items-center py-5 transition-all duration-300",
            @sidebar_collapsed && "justify-center",
            !@sidebar_collapsed && "justify-between px-2"
          ]}>
            <div class="flex items-center gap-3 overflow-hidden">
              <div class="h-9 w-9 shrink-0 rounded-lg bg-slate-900 dark:bg-slate-100 flex items-center justify-center text-white dark:text-slate-900 shadow-sm">
                <img src="/images/logo.png" alt="Logo" class="h-[18px] w-[18px]" />
              </div>
              <div :if={!@sidebar_collapsed} class="whitespace-nowrap transition-opacity duration-200">
                <div class="text-[14px] font-semibold leading-tight text-gray-900 dark:text-slate-100">Parallel Monitor</div>
                <div class="text-[10px] tracking-wide text-gray-400 dark:text-slate-400">VOTAS ADMIN PANEL</div>
              </div>
            </div>

            <!-- Toggle Button (Expanded Mode) -->
            <button
              :if={!@sidebar_collapsed}
              phx-click="toggle-sidebar"
              title="Collapse Sidebar"
              class="p-1.5 rounded-lg text-gray-400 hover:text-gray-600 dark:hover:text-slate-200 hover:bg-gray-100 dark:hover:bg-slate-800 transition-colors"
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                <path d="M11 19l-7-7 7-7M18 19l-7-7 7-7" />
              </svg>
            </button>
          </div>

          <!-- Toggle Button (Collapsed Mode) -->
          <div :if={@sidebar_collapsed} class="flex justify-center mb-2">
            <button
              phx-click="toggle-sidebar"
              title="Expand Sidebar"
              class="p-1.5 rounded-lg text-gray-400 hover:text-gray-600 dark:hover:text-slate-200 hover:bg-gray-100 dark:hover:bg-slate-800 transition-colors"
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                <path d="M13 5l7 7-7 7M6 5l7 7-7 7" />
              </svg>
            </button>
          </div>

          <!-- Navigation items -->
          <nav class="mt-2 space-y-1 text-[14px]">
            <.link
              :for={{key, label, icon} <- @nav_pages}
              patch={~p"/admin/switch?page=#{key}"}
              title={if @sidebar_collapsed, do: label, else: nil}
              class={[
                "nav-item w-full flex items-center rounded-lg transition-colors group",
                @sidebar_collapsed && "justify-center p-2.5",
                !@sidebar_collapsed && "gap-3 px-3 py-2 text-left",
                @page == key && "text-brand bg-blue-50 dark:bg-blue-500/10 font-medium",
                @page != key && "text-gray-500 dark:text-slate-400 hover:bg-gray-100 dark:hover:bg-slate-900"
              ]}
            >
              <.icon name={icon} class="h-5 w-5 shrink-0 opacity-80 group-hover:opacity-100 transition-opacity" />
              <span :if={!@sidebar_collapsed} class="truncate">
                {label}
              </span>
            </.link>

            <.link
              :for={{key, label, icon} <- @ec8a_nav_items}
              patch={~p"/admin/switch?page=#{key}"}
              title={if @sidebar_collapsed, do: label, else: nil}
              class={[
                "nav-item w-full flex items-center rounded-lg transition-colors group",
                @sidebar_collapsed && "justify-center p-2.5",
                !@sidebar_collapsed && "gap-3 px-3 py-2 text-left",
                @page == key && "text-brand bg-blue-50 dark:bg-blue-500/10 font-medium",
                @page != key && "text-gray-500 dark:text-slate-400 hover:bg-gray-100 dark:hover:bg-slate-900"
              ]}
            >
              <.icon name={icon} class="h-5 w-5 shrink-0 opacity-80 group-hover:opacity-100 transition-opacity" />
              <span :if={!@sidebar_collapsed} class="truncate">
                {label} EC8A
              </span>
            </.link>
          </nav>
        </div>

        <!-- Sidebar Footer -->
        <div class={[
          "py-4 border-t border-gray-200 dark:border-slate-800 transition-all duration-300",
          @sidebar_collapsed && "px-1 text-center",
          !@sidebar_collapsed && "px-2"
        ]}>
          <div :if={!@sidebar_collapsed} class="mb-3">
            <div class="text-[13px] font-medium truncate text-gray-800 dark:text-slate-100">paul olukayode</div>
            <div class="text-[11px] text-gray-400 dark:text-slate-400">admin</div>
          </div>
          <button
            title={if @sidebar_collapsed, do: "Sign Out", else: nil}
            class={[
              "w-full text-[13px] font-medium border border-gray-200 dark:border-slate-700 rounded-lg py-1.5 hover:bg-gray-50 dark:hover:bg-slate-900 transition-colors flex items-center justify-center gap-2 text-gray-600 dark:text-slate-300",
              @sidebar_collapsed && "px-0"
            ]}
          >
            <.icon name="hero-arrow-right-on-rectangle" class="h-4 w-4 shrink-0" />
            <span :if={!@sidebar_collapsed}>Sign Out</span>
          </button>
        </div>
      </aside>

      <!-- ============ MAIN ============ -->
      <div class="flex-1 flex flex-col min-w-0">
        <header class="sticky top-0 z-20 flex items-center justify-between gap-4 px-8 h-16 bg-white/80 dark:bg-slate-950/80 backdrop-blur border-b border-gray-200 dark:border-slate-800/60">
          <!-- LEFT: date -->
          <div class="flex items-center gap-3">
            <div class="h-9 w-9 rounded-xl bg-blue-50 dark:bg-blue-500/10 text-brand flex items-center justify-center">
              <.icon name="hero-calendar-days" class="h-5 w-5" />
            </div>
            <div class="leading-tight">
              <div class="text-[11px] uppercase tracking-wider text-gray-400 dark:text-slate-500">Today</div>
              <div class="text-[14px] font-semibold text-gray-800 dark:text-slate-100">{@today_label}</div>
            </div>
          </div>

          <!-- RIGHT: controls, vertically centered -->
          <div class="flex items-center gap-3 ml-auto">
            <button
              type="button"
              aria-label="Toggle dark mode"
              phx-click={
                JS.toggle_attribute({"data-theme", "dark", "light"}, to: "html")
                |> JS.toggle_class("hidden", to: "#icon-moon")
                |> JS.toggle_class("hidden", to: "#icon-sun")
              }
              class="h-9 w-9 rounded-full border border-gray-200 dark:border-slate-700 flex items-center justify-center text-gray-500 dark:text-slate-300 hover:bg-gray-100 dark:hover:bg-slate-800 hover:scale-105 active:scale-95 transition"
            >
              <svg id="icon-moon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                <path d="M21 12.8A9 9 0 1111.2 3a7 7 0 009.8 9.8z" />
              </svg>
              <svg id="icon-sun" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" class="hidden">
                <circle cx="12" cy="12" r="4" /><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" />
              </svg>
            </button>

            <div class="flex items-center gap-2 h-9 px-3.5 rounded-full text-[13px] font-medium text-emerald-700 dark:text-emerald-300 bg-emerald-50 dark:bg-emerald-500/10 border border-emerald-200 dark:border-emerald-500/20">
              <span class="relative flex h-2 w-2">
                <span class="absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75 animate-ping"></span>
                <span class="relative inline-flex h-2 w-2 rounded-full bg-emerald-500"></span>
              </span>
              Online
            </div>
          </div>
        </header>

        <main class="px-8 pb-10 pt-6 flex-1 overflow-x-auto">
          <.dashboard_page :if={@page == "dashboard" && assigns[:field_officer]} field_officer={@field_officer} />
          <.parties_page :if={@page == "parties" && assigns[:parties]} parties={@parties} />
          <.live_page :if={@page == "live" && assigns[:field_officer]} field_officer={@field_officer} />
          <.cdrs_page :if={@page == "cdrs" && assigns[:cdrs]} cdrs={@cdrs} />

          <.field_officers_page :if={@page == "field_officers" && assigns[:field_officer_states]} field_officer_states={@field_officer_states} />

          <.placeholder_page :if={@page not in @implemented_pages && !election_type_page?(@page) && !ec8a_page?(@page)} page={@page} />

          <.presidential_page
            :if={election_type_page?(@page) && @current_election_name == "Presidential" && assigns[:collation]}
            collation={@collation}
            selected_ward={@collation_ward}
            election_name={@current_election_name}
          />

          <.governorship_page
            :if={election_type_page?(@page) && @current_election_name == "Governorship" && assigns[:candidates]}
            candidates={@candidates} state_results={@state_results} state_filter={@state_filter}
          />
          <.senatorial_page
            :if={election_type_page?(@page) && @current_election_name == "Senatorial" && assigns[:candidates]}
            candidates={@candidates} state_results={@state_results} state_filter={@state_filter}
          />
          <.assembly_page
            :if={election_type_page?(@page) && @current_election_name == "Assembly" && assigns[:candidates]}
            candidates={@candidates} state_results={@state_results} state_filter={@state_filter}
          />
          <.lg_page
            :if={election_type_page?(@page) && @current_election_name == "LG" && assigns[:candidates]}
            candidates={@candidates} state_results={@state_results} state_filter={@state_filter}
          />
          <.reps_page
            :if={election_type_page?(@page) && @current_election_name == "H. of Reps" && assigns[:candidates]}
            candidates={@candidates} state_results={@state_results} state_filter={@state_filter}
          />

          <.presidential_ec8a_page
            :if={ec8a_page?(@page) && @current_ec8a_election_name == "Presidential" && assigns[:ec8a_officers] && assigns[:ec8a_reports]}
            officers={@ec8a_officers}
            reports={@ec8a_reports}
            election_name={@current_ec8a_election_name}
          />
        </main>
      </div>
    </div>

    <.cdr_modal :if={@selected_cdr_index && assigns[:cdrs]} cdr={Enum.at(@cdrs, @selected_cdr_index)} />
    <.election_result_modal :if={@selected_election_result} record={@selected_election_result} />

    <.live_modal
      :if={@selected_live_officer}
      officer={@selected_live_officer}
      messages={@messages}
      presiding_officer_report={@presiding_officer_report}
      loading_presiding_officer={@loading_presiding_officer}
      pu_security_report={@pu_security_report}
      loading_pu_security={@loading_pu_security}
      ward_security_report={@ward_security_report}
      loading_ward_security={@loading_ward_security}
      party_agent_report={@party_agent_report}
      loading_party_agent={@loading_party_agent}
    />
    """
  end
end
