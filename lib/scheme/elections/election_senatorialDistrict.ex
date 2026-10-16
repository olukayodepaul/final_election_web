defmodule WebApiElection.Elections.SenatorialDistrict do
  use Ecto.Schema
  import Ecto.Changeset

  schema "senatorial_districts" do
    field :lg_id,     :integer
    field :state_id,  :integer
    field :code,      :string
    field :name,      :string
    field :status,    :integer, default: 1

    timestamps(type: :utc_datetime, inserted_at: :created_at)
  end

  @required_fields [
    :lg_id,
    :state_id,
    :code,
    :name
  ]

  @optional_fields [
    :status
  ]

  def changeset(senatorial_district, attrs) do
    senatorial_district
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:lg_id, name: :senatorial_districts_lg_id_index)
    |> foreign_key_constraint(:lg_id)
    |> foreign_key_constraint(:state_id)
  end
end
