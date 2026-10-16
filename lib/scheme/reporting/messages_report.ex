defmodule WebApiElection.Reporting.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [inserted_at: :created_at, updated_at: :updated_at, type: :utc_datetime]

  schema "messages" do
    field :user_id, :integer
    field :uuids, :string
    field :pu_id, :integer
    field :ward_id, :integer
    field :lg_id, :integer
    field :state_id, :integer
    field :payload, :string, default: ""
    field :payload_type, :string
    field :owner, :integer
    field :transport_status, :string

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [
      :user_id,
      :uuids,
      :pu_id,
      :ward_id,
      :lg_id,
      :state_id,
      :payload,
      :payload_type,
      :owner,
      :transport_status
    ])
    |> validate_required([
      :user_id,
      :uuids,
      :pu_id,
      :ward_id,
      :lg_id,
      :state_id,
      :payload,
      :payload_type,
      :owner,
      :transport_status
    ])
    |> foreign_key_constraint(:user_id, name: :msg_fk_user)
  end
end
