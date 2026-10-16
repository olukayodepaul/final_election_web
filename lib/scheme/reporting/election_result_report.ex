defmodule WebApiElection.Reporting.ElectionResultReport do
  use Ecto.Schema
  import Ecto.Changeset

  schema "election_result_report" do
    field :user_id, :integer
    field :payload, :map, default: %{}
    field :pu_id, :integer
    field :ward_id, :integer
    field :lg_id, :integer
    field :state_id, :integer
    field :election_id, :integer
    field :upload_url, :string

    timestamps(inserted_at: :created_at, updated_at: :updated_at)
  end

  def changeset(report, attrs) do
    report
    |> cast(attrs, [
      :user_id,
      :payload,
      :pu_id,
      :ward_id,
      :lg_id,
      :state_id,
      :election_id,
      :upload_url
    ])
    |> validate_required([:user_id, :election_id])
  end


end
