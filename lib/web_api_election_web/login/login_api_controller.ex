defmodule WebApiElectionWeb.ApiLoginController do
  use WebApiElectionWeb, :controller
  alias WebApiElection.LoginQuery

  def api_login(conn, %{"username" => username, "password" => password}) do

    case LoginQuery.get_field_officer(username) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          status: %{
            code: 401,
            message: :unauthorized
          }
        })

      result ->

        if Bcrypt.verify_pass(password, result.password) do

          {:ok, tokens} = JWT.Issuer.generate_tokens(%{
            device_id: "bim#{result.id}",
            eid:       "bim#{result.id}@bimip.com",
            user_id:   "#{result.id}"
          })

          conn
          |> put_status(:ok)
          |> json(%{
            status: %{
              code: 200,
              message: :ok
            },
            party_details: [
                %{code: "1", party_logo_url: "Alice", name: "false"}
              ],
            data: %{
              device_id:         result.id,
              full_name:         result.full_name,
              username:          result.username,
              roles:             result.roles,
              role_id:           result.role_id,
              from_eid:          "bim#{result.field_officer_id}@bimip.com",
              to_eid:            "bim#{result.supervisor_id}@bimip.com",
              start_date:        result.start_date,
              end_date:          result.end_date,
              election_date:     result.election_date |> Calendar.strftime("%a, %d %b"),
              lead_ele_type:     result.lead_ele_type,
              pin:               result.pin,
              token:             tokens,
              trail_ele_type:    result.trail_ele_type,
              lead_ele_name:     result.lead_ele_name,
              trail_ele_name:    result.trail_ele_name,
              lat:               result.lat  && Decimal.to_float(result.lat),
              long:              result.long && Decimal.to_float(result.long),
              registered_voters: result.registered_voters,
              pvc_collected:     result.pvc_collected,
              polling_unit_id:   result.polling_unit_id,
              polling_unit_name: result.polling_unit_name,
              polling_unit_code: result.polling_unit_code,
              ward_code:         result.ward_code,
              ward_name:         result.ward_name,
              ward_id:           result.ward_id,
              lg_code:           result.lg_code,
              lg_name:           result.lg_name,
              lg_id:             result.lg_id,
              state_code:        result.state_code,
              state_name:        result.state_name,
              state_id:          result.state_id,
              total_pu_in_ward:  result.total_pu_in_ward,
              elections:         result.elections
            }
          })
        else
          conn
          |> put_status(:unauthorized)
          |> json(%{
            status: %{
              code: 401,
              message: "invalid password"
            }
          })
        end
    end
  end

  def api_login(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      status: %{
        code: 400,
        message: :bad_request
      }
    })
  end

end
