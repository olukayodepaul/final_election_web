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
    field :is_conclusive_time,         :utc_datetime # timestamp(0) without time zone in SQL
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
    field :is_voters_verify_with_bvas_time,           :utc_datetime
    field :collation_status_time,                      :utc_datetime
    field :result_upload_to_irev_time,                 :utc_datetime
    field :is_bvas_working_time,                       :utc_datetime
    field :is_bvas_available_time,                     :utc_datetime
    field :did_inec_clear_agent_time,                  :utc_datetime
    field :security_present_time,                      :utc_datetime
    field :is_pu_officer_at_collation_center_ar_time, :utc_datetime

    field :accr_started_at,   :utc_datetime
    field :voting_started_at, :utc_datetime
    field :arrival_time,      :utc_datetime

    # Ward collation center fields
    field :is_inec_officer_at_collation_center, :boolean
    field :is_inec_officer_same_as_pu_officer,  :boolean
    field :result_upload_to_irev,               :boolean

    # Timestamps (mapped to created_at / updated_at in DB)
    timestamps(type: :utc_datetime, inserted_at: :created_at, updated_at: :updated_at)
  end

  @updatable_fields [
    :inec_ar_device_time,
    :official_no,
    :is_bvas_available,
    :is_bvas_working,
    :has_accr_commence,
    :has_voting_commence,
    :is_voters_verify_with_bvas,
    :is_conclusive,
    :is_conclusive_time,
    :accr_started_at,
    :voting_started_at
  ]

  def changeset(elec_current_state, attrs) do
    elec_current_state
    |> cast(attrs, @updatable_fields)
    |> inec_ar_device_time()
    |> accr_started_at()
    |> voting_started_at()
    |> is_voters_verify_with_bvas_time()
    |> is_bvas_working_time()
    |> is_bvas_available_time()
    |> voting_started_at()
  end

  defp inec_ar_device_time(changeset) do
    case get_change(changeset, :inec_ar_device_time) do
      nil ->
        # Value is the same as in the DB (or wasn't sent). Keep the old time.
        delete_change(changeset, :inec_ar_device_time)

      _new_value ->
        # Value is different from the DB, so stamp a fresh time.
        now = DateTime.utc_now() |> DateTime.truncate(:second)
        put_change(changeset, :inec_ar_time, now)
    end
  end

  defp accr_started_at(changeset) do
    case get_change(changeset, :has_accr_commence) do
      nil ->
        # Value is the same as in the DB (or wasn't sent). Keep the old time.
        delete_change(changeset, :has_accr_commence)

      _new_value ->
        # Value is different from the DB, so stamp a fresh time.
        now = DateTime.utc_now() |> DateTime.truncate(:second)
        put_change(changeset, :accr_started_at, now)
    end
  end

  defp voting_started_at(changeset) do
    case get_change(changeset, :has_voting_commence) do
      nil ->
        # Value is the same as in the DB (or wasn't sent). Keep the old time.
        delete_change(changeset, :has_voting_commence)

      _new_value ->
        # Value is different from the DB, so stamp a fresh time.
        now = DateTime.utc_now() |> DateTime.truncate(:second)
        put_change(changeset, :voting_started_at, now)
    end
  end

  defp is_voters_verify_with_bvas_time(changeset) do
    case get_change(changeset, :is_voters_verify_with_bvas) do
      nil ->
        # Value is the same as in the DB (or wasn't sent). Keep the old time.
        delete_change(changeset, :is_voters_verify_with_bvas)

      _new_value ->
        # Value is different from the DB, so stamp a fresh time.
        now = DateTime.utc_now() |> DateTime.truncate(:second)
        put_change(changeset, :is_voters_verify_with_bvas_time, now)
    end
  end

  defp is_bvas_working_time(changeset) do
    case get_change(changeset, :is_bvas_working) do
      nil ->
        # Value is the same as in the DB (or wasn't sent). Keep the old time.
        delete_change(changeset, :is_bvas_working)

      _new_value ->
        # Value is different from the DB, so stamp a fresh time.
        now = DateTime.utc_now() |> DateTime.truncate(:second)
        put_change(changeset, :is_bvas_working_time, now)
    end
  end

  defp is_bvas_available_time(changeset) do
    case get_change(changeset, :is_bvas_available) do
      nil ->
        # Value is the same as in the DB (or wasn't sent). Keep the old time.
        delete_change(changeset, :is_bvas_available)

      _new_value ->
        # Value is different from the DB, so stamp a fresh time.
        now = DateTime.utc_now() |> DateTime.truncate(:second)
        put_change(changeset, :is_bvas_available_time, now)
    end
  end

  defp is_bvas_available_time(changeset) do
    case get_change(changeset, :is_bvas_available) do
      nil ->
        # Value is the same as in the DB (or wasn't sent). Keep the old time.
        delete_change(changeset, :is_bvas_available)

      _new_value ->
        # Value is different from the DB, so stamp a fresh time.
        now = DateTime.utc_now() |> DateTime.truncate(:second)
        put_change(changeset, :is_bvas_available_time, now)
    end
  end

  defp voting_started_at(changeset) do
    case get_change(changeset, :has_voting_commence) do
      nil ->
        # Value is the same as in the DB (or wasn't sent). Keep the old time.
        delete_change(changeset, :has_voting_commence)

      _new_value ->
        # Value is different from the DB, so stamp a fresh time.
        now = DateTime.utc_now() |> DateTime.truncate(:second)
        put_change(changeset, :voting_started_at, now)
    end
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
    :did_inec_clear_agent
  ]

  def party_agent_changeset(elec_current_state, attrs) do
    elec_current_state
    |> cast(attrs, @party_fields)
    |> arrival_time()
    |> did_inec_clear_agent_time()
  end

  defp arrival_time(changeset) do
    case fetch_change(changeset, :is_agent_at_polling_unit) do
      {:ok, new_value} when new_value != changeset.data.did_inec_clear_agent ->
        put_change(changeset, :arrival_time, DateTime.utc_now() |> DateTime.truncate(:second))

      _ ->
        changeset
    end
  end

  defp did_inec_clear_agent_time(changeset) do
    case fetch_change(changeset, :did_inec_clear_agent) do
      {:ok, new_value} when new_value != changeset.data.did_inec_clear_agent ->
        put_change(changeset, :did_inec_clear_agent_time, DateTime.utc_now() |> DateTime.truncate(:second))

      _ ->
        changeset
    end
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
