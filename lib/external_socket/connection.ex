defmodule WebApiElection.ExternalSocket.Connection do
  @moduledoc """
  Persistent per-user WebSocket connection.

  Design goals:
    * Never let an unexpected payload/crash kill the process silently -
      all frame handling is wrapped in try/rescue/catch.
    * Reconnect with exponential backoff (capped) instead of a tight retry
      loop that gets you rate-limited or banned.
    * Detect "silently dead" connections (TCP up, server not responding)
      via a ping/pong watchdog, and force a reconnect if pongs stop.
    * Stay registered under the same Registry key across internal
      reconnects (WebSockex's {:reconnect, state} keeps the same pid).
    * If the process does crash outright, WebApiElection.ExternalSocket.Supervisor
      (DynamicSupervisor, restart: :transient) is the safety net that
      rebuilds it - but that should be a rare last resort, not the normal path.
  """

  use WebSockex
  require Logger

  @max_backoff_ms 30_000
  @base_backoff_ms 500
  @ping_interval_ms 25_000
  @pong_timeout_ms 65_000
  # A connection only "counts" as stable (resetting backoff to 0) after it
  # has stayed open this long. This prevents a connect -> instant-disconnect
  # flap loop from resetting reconnect_attempts on every cycle, which would
  # otherwise defeat exponential backoff entirely and hammer the server at
  # a near-constant interval forever.
  @stable_after_ms 15_000

  ## --- Public API ---------------------------------------------------------

  @doc """
  Starts a socket process tied to a specific user_id.
  Expects opts: [user_id: _, token: _, url: _]
  """
  def start_link(opts) do
    user_id = Keyword.fetch!(opts, :user_id)
    token = Keyword.fetch!(opts, :token)
    raw_url = Keyword.fetch!(opts, :url)

    url = String.replace(raw_url, ~r/^ws:\/\//, "wss://")
    uri = URI.parse(url)

    auth_val = if String.starts_with?(token, "Bearer "), do: token, else: "Bearer #{token}"

    extra_headers = [
      {"origin", "https://#{uri.host}"},
      {"token", auth_val},
      {"authorization", auth_val},
      {"ngrok-skip-browser-warning", "true"},
      {"user-agent", "PostmanRuntime/7.39.0"}
    ]

    name = via_tuple(user_id)
    now = System.monotonic_time(:millisecond)

    state = %{
      user_id: user_id,
      token: token,
      url: url,
      extra_headers: extra_headers,
      eid: "bim#{user_id}@bimip.com",
      reconnect_attempts: 0,
      ping_timer: nil,
      last_pong: now,
      stability_timer: nil,
      flap_count: 0
    }

    WebSockex.start_link(
      url,
      __MODULE__,
      state,
      name: name,
      extra_headers: extra_headers,
      insecure: true,
      async: true,
      handle_initial_conn_failure: true
    )
  end

  def via_tuple(user_id) do
    {:via, Registry, {WebApiElection.UserSocketRegistry, user_id}}
  end

  def send_chat_message(message) do
    frame = build_message_frame(message)
    msg_type = Map.get(message, :msg_type, "TEXT")
    stored = if msg_type == "TEXT", do: message.message, else: Map.get(message, :media_url, "")

    case Registry.lookup(WebApiElection.UserSocketRegistry, message.from) do
      [{pid, _}] ->
        case WebApiElection.Reporting.MessageQuery.insert_message(
               message.to,
               Ecto.UUID.generate(),
               message.pu_code,
               message.ward_code,
               message.lg_code,
               message.state_code,
               stored,
               msg_type,
               1,
               "SENT"
             ) do
          {:ok, _saved_message} ->
            :ok

          {:error, changeset} ->
            Logger.error("Failed to insert outgoing message: #{inspect(changeset.errors)}")
        end

        WebSockex.send_frame(pid, {:binary, frame})
        :ok

      [] ->
        {:error, :not_connected}
    end
  end

  ## --- WebSockex callbacks --------------------------------------------------

  @impl true
  def handle_connect(_conn, state) do
    Logger.info(
      "🟢 WebSocket connected for User ID: #{state.user_id} " <>
        "(attempt ##{state.reconnect_attempts}, flap_count=#{state.flap_count})"
    )

    cancel_ping_timer(state)
    timer_ref = schedule_ping()
    now = System.monotonic_time(:millisecond)

    # Don't reset reconnect_attempts here - if this connection turns out to
    # be a flap (closes again within @stable_after_ms), we want backoff to
    # keep growing rather than restarting at 0 every time. It only resets
    # once :mark_stable actually fires below.
    stability_timer = Process.send_after(self(), :mark_stable, @stable_after_ms)

    {:ok, %{state | ping_timer: timer_ref, last_pong: now, stability_timer: stability_timer}}
  end

  @impl true
  def handle_frame({:binary, data}, state) do
    # Any binary frame from the server - ping ack, message, anything - is
    # proof the connection is alive. This protocol acks pings at the
    # application layer (route_id 3), not via native WS pong frames, so
    # liveness must be tracked here rather than in handle_pong/2.
    state = %{state | last_pong: System.monotonic_time(:millisecond)}

    if data == <<>> do
      {:ok, state}
    else
      safe_handle_frame(data, state)
    end
  end

  def handle_frame({:text, _msg}, state), do: {:ok, state}
  def handle_frame({_type, _msg}, state), do: {:ok, state}

  # Every branch below is isolated so a bad payload can never crash the
  # connection - worst case it's logged and dropped.
  defp safe_handle_frame(data, state) do
    case safe_decode_route(data) do
      {:ok, route, decoded} ->
        handler = Map.get(dispatch_map(), route, &default_handler/2)

        try do
          handler.(state, decoded)
        rescue
          e ->
            Logger.error(
              "Handler for route=#{route} user=#{state.user_id} crashed: " <>
                Exception.format(:error, e, __STACKTRACE__)
            )

            {:ok, state}
        catch
          kind, reason ->
            Logger.error(
              "Handler for route=#{route} user=#{state.user_id} threw #{kind}: #{inspect(reason)}"
            )

            {:ok, state}
        end

      {:error, reason} ->
        Logger.error("Failed to decode route for user #{state.user_id}: #{inspect(reason)}")
        {:ok, state}
    end
  end

  defp dispatch_map do
    %{
      3 => &handle_ping_ack/2,
      6 => &handle_message/2
    }
  end

  ## --- Ping / pong watchdog --------------------------------------------------

  @impl true
  def handle_info(:send_ping, state) do
    now = System.monotonic_time(:millisecond)

    if now - state.last_pong > @pong_timeout_ms do
      Logger.warning(
        "⚠️ No pong for #{@pong_timeout_ms}ms from user #{state.user_id}'s server - " <>
          "connection considered dead, forcing close+reconnect"
      )

      # {:close, state} makes WebSockex close the socket, which then
      # triggers handle_disconnect -> our backoff reconnect logic below.
      {:close, state}
    else
      case safe_build_ping_frame(state) do
        {:ok, binary_ping} ->
          timer_ref = schedule_ping()
          {:reply, {:binary, binary_ping}, %{state | ping_timer: timer_ref}}

        {:error, reason} ->
          Logger.error("Failed to build ping frame for user #{state.user_id}: #{inspect(reason)}")
          timer_ref = schedule_ping()
          {:ok, %{state | ping_timer: timer_ref}}
      end
    end
  end

  def handle_info(:mark_stable, state) do
    Logger.info(
      "✅ Connection for user #{state.user_id} stable for #{@stable_after_ms}ms, " <>
        "resetting backoff (was attempt ##{state.reconnect_attempts})"
    )

    {:ok, %{state | reconnect_attempts: 0, flap_count: 0, stability_timer: nil}}
  end

  def handle_info(_msg, state), do: {:ok, state}

  @impl true
  def handle_pong(_pong_frame, state) do
    {:ok, %{state | last_pong: System.monotonic_time(:millisecond)}}
  end

  defp safe_build_ping_frame(state) do
    {:ok, build_ping_frame(state)}
  rescue
    e -> {:error, e}
  end

  defp build_ping_frame(state) do
    Bimip.MessageScheme.encode(%Bimip.MessageScheme{
      route_id: 3,
      payload:
        {:ping,
         %Bimip.Ping{
           id: Ecto.UUID.generate(),
           from: %Bimip.Identity{eid: state.eid},
           type: 1,
           timestamp: System.system_time(:millisecond)
         }}
    })
  end

  defp schedule_ping do
    Process.send_after(self(), :send_ping, @ping_interval_ms)
  end

  defp cancel_ping_timer(%{ping_timer: nil}), do: :ok

  defp cancel_ping_timer(%{ping_timer: ref}) do
    Process.cancel_timer(ref)

    receive do
      :send_ping -> :ok
    after
      0 -> :ok
    end
  end

  defp cancel_stability_timer(%{stability_timer: nil}), do: :ok

  defp cancel_stability_timer(%{stability_timer: ref}) do
    Process.cancel_timer(ref)

    receive do
      :mark_stable -> :ok
    after
      0 -> :ok
    end
  end

  ## --- Reconnect with capped exponential backoff -----------------------------

  @impl true
  def handle_disconnect(disconnect_map, state) do
    cancel_ping_timer(state)
    cancel_stability_timer(state)

    attempts = state.reconnect_attempts + 1
    flap_count = state.flap_count + 1
    backoff = min(@max_backoff_ms, round(:math.pow(2, min(attempts, 10)) * @base_backoff_ms))

    Logger.error(
      "🔴 User #{state.user_id} disconnected (reason: #{inspect(disconnect_map[:reason])}). " <>
        "Reconnecting in #{backoff}ms (attempt ##{attempts}, flap_count=#{flap_count})..."
    )

    if flap_count >= 8 do
      Logger.error(
        "🚨 User #{state.user_id}: #{flap_count} rapid connect/disconnect cycles in a row " <>
          "without going stable. This usually means an expired/invalid token, a dead tunnel " <>
          "URL, or the server rejecting/kicking this connection at the app layer right after " <>
          "handshake - backoff alone will not fix that. Still retrying at capped backoff, " <>
          "but this needs investigation (check the token's exp claim and that the ngrok URL " <>
          "is still the live one)."
      )
    end

    # Runs inside this connection's own process only - does not block
    # anything else in the app.
    Process.sleep(backoff)

    now = System.monotonic_time(:millisecond)

    {:reconnect,
     %{
       state
       | reconnect_attempts: attempts,
         flap_count: flap_count,
         ping_timer: nil,
         stability_timer: nil,
         last_pong: now
     }}
  end

  ## --- Ping ack from server ---------------------------------------------------

  defp handle_ping_ack(state, %Bimip.MessageScheme{payload: {:ping, _ping}}) do
    {:ok, state}
  end

  defp handle_ping_ack(state, _decoded), do: {:ok, state}

  ## --- Message handling -------------------------------------------------------

  defp handle_message(state, %Bimip.MessageScheme{payload: {:message, message}}) do
    with {:ok, outer} <- Jason.decode(message.payload),
         {:ok, inner} <- decode_inner_message(outer),
         {:ok, user_id} <- parse_user_id(outer["user_id"]) do
      case outer["category"] do
        "1" -> insert_message(state, user_id, outer, inner)
        "2" -> insert_polling_unit_report(state, user_id, outer, inner)
        "3" -> insert_polling_unit_security_report(state, user_id, outer, inner)
        "4" -> insert_ward_security_report(state, user_id, outer, inner)
        "5" -> insert_party_agent_report(state, user_id, outer, inner)
        "6" -> election_forms_upload(state, user_id, outer, inner)
        _ -> :ok
      end
    else
      {:error, reason} ->
        Logger.error("Failed to parse message payload for user #{state.user_id}: #{inspect(reason)}")
    end

    {:ok, state}
  end

  defp handle_message(state, _decoded), do: {:ok, state}

  ## --- Attr helpers -----------------------------------------------------------

  # Only writes a key when there is a real value, so a payload that omits a
  # field never overwrites a good stored value with "" / "NULL" / nil.
  defp put_if(attrs, _key, nil), do: attrs
  defp put_if(attrs, key, value), do: Map.put(attrs, key, value)

  defp put_time_if(attrs, key, true, time), do: Map.put(attrs, key, time)
  defp put_time_if(attrs, _key, _false, _time), do: attrs

  # Runs the elec_current_state update and returns the saved row, or nil on failure.
  defp save_state(report_user_id, fun) do
    case fun.() do
      {:ok, saved} ->
        saved

      other ->
        Logger.error("elec_current_state update failed for #{report_user_id}: #{inspect(other)}")
        nil
    end
  end

  ## --- Polling unit (presiding officer) report --------------------------------

  defp insert_polling_unit_report(state, user_id, outer, inner) do
    case WebApiElection.Reporting.PollingUnitReportQuery.insert_report(
           user_id,
           outer["id"],
           outer["polling_unit_code"],
           outer["ward_code"],
           outer["lg_code"],
           outer["state_code"],
           inner
         ) do
      {:ok,
       %WebApiElection.Reporting.PollingUnitReport{payload: payload, user_id: report_user_id} =
           report} ->
        report_user_id = to_int(report_user_id)

        elec_outcome =
          case payload["electionOutcome"] do
            1 -> "Ongoing"
            2 -> "Collation"
            3 -> "Concluded"
            4 -> "Cancelled"
            5 -> "Disrupted"
            _ -> nil
          end

        acr_method =
          case payload["accreditationMethod"] do
            1 -> "Manual"
            2 -> "Bvas"
            _ -> nil
          end

        attrs =
          %{}
          |> put_if(:inec_ar_device_time, payload["arrivalTime"])
          |> put_if(:official_no, payload["numberOfInecOfficial"] && to_string(payload["numberOfInecOfficial"]))
          |> put_if(:is_bvas_available, payload["isBvnMachineAvail"])
          |> put_if(:is_bvas_working, payload["isBvbDeviceGoodCond"])
          |> put_if(:has_accr_commence, payload["hasAccredCommence"])
          |> put_if(:has_voting_commence, payload["hasVolingCommence"])
          |> put_if(:is_voters_verify_with_bvas, acr_method)
          |> put_if(:is_conclusive, elec_outcome)

        # 1. Save the state first, so we know the stored (first) times
        saved =
          save_state(report_user_id, fn ->
            WebApiElection.Elections.ElecCurrentStateQuery.upsert_state(report_user_id, attrs)
          end)

        # 2. Broadcast the report with the stored server times instead of the phone's text
        broadcast_report(state, with_server_times(report, saved))

      {:error, changeset} ->
        Logger.error("Failed to insert field report: #{inspect(changeset)}")

      other ->
        Logger.error("Unexpected insert_report result: #{inspect(other)}")
    end
  rescue
    e ->
      Logger.error("insert_polling_unit_report crashed: #{Exception.format(:error, e, __STACKTRACE__)}")
  end

  # Changes the broadcast copy only. Nothing here is saved.
  defp with_server_times(report, nil) do
    payload = Map.drop(report.payload, ["arrivalTime", "accrStartedAt", "votingStartedAt"])
    %{report | payload: payload}
  end

  defp with_server_times(report, saved) do
    payload =
      report.payload
      |> Map.put("arrivalTime", saved.inec_ar_time)
      |> Map.put("accrStartedAt", saved.accr_started_at)
      |> Map.put("votingStartedAt", saved.voting_started_at)
      |> Map.put("isVotersVerifyWithBvasTime", saved.is_voters_verify_with_bvas_time)
      |> Map.put("BvasFunc", saved.is_bvas_working_time)
      |> Map.put("Bavai", saved.is_bvas_available_time)
      |> Map.put("voteStart", saved.voting_started_at)
      |> Map.put("InecRr", saved.inec_ar_time)
      |> Map.put("elecConClusive", saved.is_conclusive_time)
    %{report | payload: payload}
  end

  ## --- Polling unit security report -------------------------------------------

  defp insert_polling_unit_security_report(state, user_id, outer, inner) do
    case WebApiElection.Reporting.PollingUnitSecurityReportQuery.insert_report(
           user_id,
           outer["id"],
           outer["polling_unit_code"],
           outer["ward_code"],
           outer["lg_code"],
           outer["state_code"],
           inner
         ) do
      {:ok,
       %WebApiElection.Reporting.PollingSecuriyReport{payload: payload, user_id: report_user_id} =
           report} ->
        report_user_id = to_int(report_user_id)

        attrs = put_if(%{}, :security_present, payload["securityPresence"])

        saved =
          save_state(report_user_id, fn ->
            WebApiElection.Elections.ElecCurrentStateQuery.update_security(report_user_id, attrs)
          end)

        broadcast_report(state, extract_security(report, saved))

      {:error, changeset} ->
        Logger.error("Failed to insert security report: #{inspect(changeset)}")

      other ->
        Logger.error("Unexpected insert_report result: #{inspect(other)}")
    end
  rescue
    e ->
      Logger.error(
        "insert_polling_unit_security_report crashed: #{Exception.format(:error, e, __STACKTRACE__)}"
      )
  end

  defp extract_security(report, nil), do: report

  defp extract_security(report, saved) do
    payload = Map.put(report.payload, "securityPresentTime", saved.security_present_time)
    %{report | payload: payload}
  end

  ## --- Ward security (collation) report ---------------------------------------

  defp insert_ward_security_report(state, user_id, outer, inner) do
    case WebApiElection.Reporting.WardSecurityReportQuery.insert_report(
           user_id,
           outer["id"],
           outer["polling_unit_code"],
           outer["ward_code"],
           outer["lg_code"],
           outer["state_code"],
           inner
         ) do
      {:ok,
       %WebApiElection.Reporting.WardSecurityReport{payload: payload, user_id: report_user_id} =
           report} ->
        report_user_id = to_int(report_user_id)

        party_agent_movement =
          case String.upcase(to_string(payload["partyAgentMovement"])) do
            "ARRIVED" -> "ARRIVED COLLATION CENTER"
            "DEPARTED" -> "DEPARTED PU"
            _ -> nil
          end

        attrs =
          %{}
          |> put_if(:is_pu_officer_at_collation_center, party_agent_movement)
          |> put_if(:has_proceed_to_ward, payload["collationStatus"])

        saved =
          save_state(report_user_id, fn ->
            WebApiElection.Elections.ElecCurrentStateQuery.update_ward_security(report_user_id, attrs)
          end)

        broadcast_report(state, extract_ward_collations(report, saved))

      {:error, changeset} ->
        Logger.error("Failed to insert ward security report: #{inspect(changeset)}")

      other ->
        Logger.error("Unexpected insert_report result: #{inspect(other)}")
    end
  rescue
    e ->
      Logger.error("insert_ward_security_report crashed: #{Exception.format(:error, e, __STACKTRACE__)}")
  end

  defp extract_ward_collations(report, nil), do: report

  defp extract_ward_collations(report, saved) do
    payload =
      report.payload
      |> Map.put("collationArTime", saved.is_pu_officer_at_collation_center_ar_time)
      |> Map.put("collationStatusTime", saved.collation_status_time)

    %{report | payload: payload}
  end

  ## --- Party agent report ------------------------------------------------------

  defp insert_party_agent_report(state, user_id, outer, inner) do
    result =
      WebApiElection.Reporting.PartyAgentReportQuery.insert_report(
        user_id,
        outer["id"],
        outer["polling_unit_code"],
        outer["ward_code"],
        outer["lg_code"],
        outer["state_code"],
        inner
      )

    case result do
      {:ok,
       %WebApiElection.Reporting.PartyAgentReport{payload: payload, user_id: report_user_id} =
           report} ->
        report_user_id = to_int(report_user_id)

        agent_at_pu =
          case payload["agentClearance"] do
            1 -> "Cleared"
            2 -> "Not Cleared"
            _ -> nil
          end

        attrs =
          %{}
          |> put_if(:is_agent_at_polling_unit, payload["isAtAssignedUnit"])
          |> put_if(:did_inec_clear_agent, agent_at_pu)

        saved =
          save_state(report_user_id, fn ->
            WebApiElection.Elections.ElecCurrentStateQuery.update_party_agent_security(report_user_id,attrs)
          end)

        broadcast_report(state, extract_party_agent(report, saved))

      {:error, changeset} ->
        Logger.error("Failed to insert party agent report: #{inspect(changeset)}")

      other ->
        Logger.error("Unexpected insert_report result: #{inspect(other)}")
    end
  rescue
    e ->
      Logger.error("insert_party_agent_report crashed: #{Exception.format(:error, e, __STACKTRACE__)}")
  end

  defp extract_party_agent(report, nil), do: report

  defp extract_party_agent(report, saved) do
    payload =
      report.payload
      |> Map.put("agentArrivalTime", saved.arrival_time)
      |> Map.put("clearedTime", saved.did_inec_clear_agent_time)
    %{report | payload: payload}
  end

  ## --- Election forms (EC8A etc.) upload --------------------------------------

  defp election_forms_upload(_state, user_id, outer, inner) do
    {election_type, election_name} =
      case String.split(outer["leadingName"] || "", "//", parts: 2) do
        [type, name] -> {type, name}
        [name] -> {nil, name}
      end

      type_map = decode_json(outer["type"])
      details = decode_json(type_map["electionDetails"])

      attrs = %{
        uuids: outer["id"],
        user_id: user_id,
        election_type: election_type,
        election_name: election_name,
        election_form: type_map["formCode"],
        pu: outer["polling_unit_code"],
        ward: outer["ward_code"],
        lg: outer["lg_code"],
        states: outer["state_code"],
        pu_id: details["puId"],
        ward_id: details["wardId"],
        lg_id: details["lgId"],
        state_id: details["stateId"],
        results: decode_json(inner),
        image_url: outer["remote_media_url"],
        variables: type_map
      }

    case WebApiElection.Reporting.ElectionResultReportQuery.insert_report(attrs) do
      {:ok, _report} ->
        :ok

      {:error, changeset} ->
        Logger.error("Failed to insert election form upload: #{inspect(changeset.errors)}")
    end
  rescue
    e ->
      Logger.error("election_forms_upload crashed: #{Exception.format(:error, e, __STACKTRACE__)}")
  end

  ## --- Chat message -------------------------------------------------------------

  defp insert_message(state, user_id, outer, _inner) do
    msg_type = outer["msg_type"]

    payload_string =
      case msg_type do
        "TEXT" -> outer["message"] || ""
        "IMAGE" -> outer["remote_media_url"] || ""
        "VIDEO" -> outer["remote_media_url"] || ""
        "AUDIO" -> outer["remote_media_url"] || ""
        _ -> ""
      end

    case WebApiElection.Reporting.MessageQuery.insert_message(
           user_id,
           outer["id"],
           outer["polling_unit_code"],
           outer["ward_code"],
           outer["lg_code"],
           outer["state_code"],
           payload_string,
           msg_type || "TEXT",
           0,
           "SENT"
         ) do
      {:ok, message} ->
        broadcast_report(state, message)

      {:error, changeset} ->
        Logger.error("Failed to insert message: #{inspect(changeset.errors)}")
    end
  rescue
    e -> Logger.error("insert_message crashed: #{Exception.format(:error, e, __STACKTRACE__)}")
  end

  defp broadcast_report(state, report) do
    Phoenix.PubSub.broadcast(
      WebApiElection.PubSub,
      "inec_official:#{state.user_id}",
      {:inec_official, report}
    )
  end

  ## --- Safe parsing helpers -------------------------------------------------

  defp to_int(val) when is_integer(val), do: val

  defp to_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {int, _rest} -> int
      :error -> nil
    end
  end

  defp to_int(_), do: nil

  defp decode_json(value) when is_map(value), do: value

  defp decode_json(value) when is_binary(value) do
    case Jason.decode(value) do
      {:ok, map} when is_map(map) -> map
      _ -> %{}
    end
  end

  defp decode_json(_), do: %{}

  defp parse_user_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {int, ""} -> {:ok, int}
      _ -> {:error, {:invalid_user_id, id}}
    end
  end

  defp parse_user_id(id) when is_integer(id), do: {:ok, id}
  defp parse_user_id(id), do: {:error, {:invalid_user_id, id}}

  defp decode_inner_message(%{"message" => inner_str}) when is_binary(inner_str) do
    case Jason.decode(inner_str) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, _} -> {:ok, inner_str}
    end
  end

  defp decode_inner_message(_outer), do: {:ok, nil}

  defp default_handler(state, decoded) do
    route = Map.get(decoded, :route_id, "unknown")
    Logger.warning("Unhandled route_id=#{route} for user #{state.user_id}")
    {:ok, state}
  end

  defp safe_decode_route(data) do
    with %Bimip.MessageScheme{route_id: route} = decoded <- Bimip.MessageScheme.decode(data) do
      {:ok, route, decoded}
    else
      _ -> {:error, :invalid_route}
    end
  rescue
    e -> {:error, e}
  end

  ## --- Outgoing message frame -----------------------------------------------

  defp build_message_frame(message) do
    id = Ecto.UUID.generate()
    timestamp = System.system_time(:millisecond)
    msg_type = Map.get(message, :msg_type, "TEXT")

    payload_json =
      Jason.encode!(%{
        "id" => id,
        "category" => "1",
        "sub_category" => "1",
        "sub_sub_category" => "0",
        "type" => msg_type,
        "msg_type" => msg_type,
        "message" => message.message,
        "remote_media_url" => Map.get(message, :media_url, ""),
        "leadingType" => "1",
        "trailType" => "1",
        "msg_state" => 0,
        "polling_unit_code" => message.pu_code,
        "ward_code" => message.ward_code,
        "lg_code" => message.lg_code,
        "state_code" => message.state_code,
        "user_id" => to_string(message.to),
        "timestamp" => timestamp,
        "owner" => 0
      })

    from_eid = "bim#{message.from}@bimip.com"
    to_eid = "bim#{message.to}@bimip.com"

    Bimip.MessageScheme.encode(%Bimip.MessageScheme{
      route_id: 6,
      payload:
        {:message,
         %Bimip.Message{
           id: id,
           from: %Bimip.Identity{eid: from_eid},
           to: %Bimip.Identity{eid: to_eid},
           timestamp: timestamp,
           payload: payload_json,
           delivery_type: 1,
           participant_role: 1,
           content_type: 1,
           message_type: 1,
           ephemeral_public_key: <<>>,
           mac: <<>>
         }}
    })
  end
end
