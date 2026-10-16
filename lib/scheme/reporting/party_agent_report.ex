defmodule WebApiElection.Reporting.PartyAgentReport do
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [inserted_at: :created_at, updated_at: :updated_at, type: :utc_datetime]

  schema "party_agent_report" do
    field :user_id, :integer
    field :uuids, :string
    field :pu_id, :integer
    field :ward_id, :integer
    field :lg_id, :integer
    field :state_id, :integer
    field :arrival_time, :utc_datetime, read_after_writes: true
    field :payload, :map, default: %{}

    timestamps()
  end

  def changeset(report, attrs) do
    report
    |> cast(attrs, [
      :user_id,
      :uuids,
      :pu_id,
      :ward_id,
      :lg_id,
      :state_id,
      :arrival_time,
      :payload
    ])
    |> validate_required([
      :user_id,
      :uuids,
      :pu_id,
      :ward_id,
      :lg_id,
      :state_id,
      :payload
    ])
    |> foreign_key_constraint(:user_id, name: :pur_fk_user)
  end
end
