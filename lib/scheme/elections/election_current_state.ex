defmodule WebApiElection.Elections.ElecCurrentState do
  use Ecto.Schema
  import Ecto.Changeset

  schema "elec_current_state" do
    field :user_id,                    :integer
    field :inec_ar_time,               :utc_datetime
    field :official_no,                :string
    field :security_present,           :string
    field :is_bvas_available,          :boolean
    field :is_bvas_working,            :boolean
    field :is_voters_verify,           :boolean
    field :has_accr_commence,          :boolean
    field :has_voting_commence,        :boolean
    field :is_conclusive_time,         :naive_datetime # timestamp(0) without time zone in SQL
    field :are_security_present,       :boolean
    field :is_agent_at_polling_unit,   :boolean

    # Matching varchar(50) in DB (or change DB to boolean via migration if intended)
    field :did_inec_clear_agent,       :string
    field :is_voters_verify_with_bvas, :string
    field :is_conclusive,              :string
    field :has_proceed_to_ward,        :string
    field :is_pu_officer_at_collation_center, :string

    # Missing field added:
    field :inec_ar_device_time,        :string

    # Timestamp fields
    field :is_voters_verify_with_bvas_time,           :naive_datetime
    field :collation_status_time,                      :naive_datetime
    field :result_upload_to_irev_time,                 :naive_datetime
    field :is_bvas_working_time,                       :naive_datetime
    field :is_bvas_available_time,                     :naive_datetime
    field :did_inec_clear_agent_time,                  :naive_datetime
    field :security_present_time,                      :naive_datetime
    field :is_pu_officer_at_collation_center_ar_time, :naive_datetime

    field :accr_started_at,   :naive_datetime
    field :voting_started_at, :naive_datetime
    field :arrival_time,      :naive_datetime

    # Ward collation center fields
    field :is_inec_officer_at_collation_center, :boolean
    field :is_inec_officer_same_as_pu_officer,  :boolean
    field :result_upload_to_irev,               :boolean

    # Timestamps (mapped to created_at / updated_at in DB)
    timestamps(type: :utc_datetime, inserted_at: :created_at, updated_at: :updated_at)
  end

  @updatable_fields [
    :inec_ar_time,
    :official_no,
    :is_bvas_available,
    :is_bvas_working,
    :is_voters_verify,
    :has_accr_commence,
    :has_voting_commence,
    :is_voters_verify_with_bvas,
    :accr_started_at,
    :voting_started_at,
    :is_conclusive,
    :is_conclusive_time,
    :inec_ar_device_time
  ]

  def changeset(elec_current_state, attrs) do
    elec_current_state
    |> cast(attrs, @updatable_fields)
    |> keep_first(:inec_ar_time)
    |> keep_first(:accr_started_at)
    |> keep_first(:voting_started_at)
  end

  @security_fields [:security_present]

  def security_changeset(elec_current_state, attrs) do
    elec_current_state
    |> cast(attrs, @security_fields)
  end

  @ward_fields [
    :has_proceed_to_ward,
    :is_pu_officer_at_collation_center,
    :is_inec_officer_same_as_pu_officer,
    :is_inec_officer_at_collation_center
  ]

  def ward_changeset(elec_current_state, attrs) do
    elec_current_state
    |> cast(attrs, @ward_fields)
  end

  @party_fields [
    :is_agent_at_polling_unit,
    :did_inec_clear_agent,
    :arrival_time
  ]

  def party_agent_changeset(elec_current_state, attrs) do
    elec_current_state
    |> cast(attrs, @party_fields)
    |> keep_first(:arrival_time)
  end

  # Once a time is stored, never overwrite it
  defp keep_first(changeset, field) do
    if Map.get(changeset.data, field) do
      delete_change(changeset, field)
    else
      changeset
    end
  end
end
