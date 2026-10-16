defmodule WebApiElection.Reporting.PollingUnitEc8aReport do
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [inserted_at: :inserted_at, updated_at: :updated_at, type: :naive_datetime]

  schema "polling_unit_reports" do
    field :user_id, :integer

    # Device/Mobile App Selected Location IDs
    field :pu_id_device, :integer
    field :ward_id_device, :integer
    field :lg_id_device, :integer
    field :state_id_device, :integer

    # AI Extracted Form Header Data
    field :document_type, :string
    field :state, :string
    field :state_code, :integer
    field :local_government, :string
    field :lg_code, :integer
    field :ward, :string
    field :ward_code, :integer
    field :polling_unit, :string
    field :pu_code, :integer
    field :uuids, :string

    # Vote Tallies
    field :registered_voters, :integer
    field :accredited_voters, :integer
    field :ballot_papers_issued, :integer
    field :spoiled_ballots, :integer
    field :rejected_votes, :integer
    field :valid_votes, :integer
    field :total_votes_cast, :integer

    # Structured Party Results (18 Parties)
    field :party_results, :map, default: %{}

    # Verification & Signatures
    field :presiding_officer_name, :string
    field :presiding_officer_signed, :boolean
    field :agent_signatures_present, :boolean
    field :ec8a_serial_number, :string
    field :result_sheet_complete, :boolean
    field :remarks, :string

    # Election / Upload Metadata
    field :election_id, :integer
    field :upload_url, :string
    field :election_name, :string
    field :user_name, :string

    # Ownership / Reporting Line
    field :manager_id, :integer

    field :state_id, :integer
    field :lg_id, :integer
    field :ward_id, :integer
    field :pu_id, :integer

    timestamps()
  end

  def changeset(report, attrs) do
    report
    |> cast(attrs, [
      :user_id,
      :pu_id_device,
      :ward_id_device,
      :lg_id_device,
      :state_id_device,
      :document_type,
      :state,
      :state_code,
      :local_government,
      :lg_code,
      :ward,
      :ward_code,
      :polling_unit,
      :pu_code,
      :uuids,
      :registered_voters,
      :accredited_voters,
      :ballot_papers_issued,
      :spoiled_ballots,
      :rejected_votes,
      :valid_votes,
      :total_votes_cast,
      :party_results,
      :presiding_officer_name,
      :presiding_officer_signed,
      :agent_signatures_present,
      :ec8a_serial_number,
      :result_sheet_complete,
      :remarks,
      :election_id,
      :upload_url,
      :election_name,
      :user_name,
      :manager_id,
      :upload_url,
      :state_id,
      :lg_id,
      :ward_id,
      :pu_id
    ])
    |> validate_required([
      :user_id,
      :pu_id_device,
      :ward_id_device,
      :lg_id_device,
      :state_id_device,
      :uuids,
      :party_results
    ])
    |> unique_constraint(:uuids, name: :polling_unit_reports_uuids_index)
    |> foreign_key_constraint(:user_id, name: :pur_fk_user)
  end
end
