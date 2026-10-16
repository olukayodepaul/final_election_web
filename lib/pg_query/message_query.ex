defmodule WebApiElection.Reporting.MessageQuery do
  alias WebApiElection.Repo
  alias WebApiElection.Reporting.Message

  def insert_message(user_id, uuids, pu_id, ward_id, lg_id, state_id, payload, payload_type, owner, trs_status) do
    %Message{}
    |> Message.changeset(%{
      user_id: user_id,
      uuids: uuids,
      pu_id: pu_id,
      ward_id: ward_id,
      lg_id: lg_id,
      state_id: state_id,
      payload: payload,
      payload_type: payload_type,
      owner: owner,
      transport_status: trs_status
    })
    |> Repo.insert()
  end

  def list_messages(user_id) do
    import Ecto.Query

    Message
    |> where([m], m.user_id == ^user_id)
    |> order_by([m], asc: m.created_at)
    |> Repo.all()
  end
end
