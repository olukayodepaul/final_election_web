defmodule WebApiElection.Reporting.ElectionResultReport do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias WebApiElection.Repo
  alias WebApiElection.Accounts.User

  # Keys read from the `results` map (string keys in the DB, atoms in the preview record).
  @result_keys [
    :ward, :state, :lg_code, :pu_code, :ward_code, :state_code,
    :polling_unit, :local_government, :document_type,
    :registered_voters, :accredited_voters, :ballot_papers_issued,
    :unused_ballot_papers, :spoiled_ballots, :rejected_votes,
    :valid_votes, :total_votes_cast, :party_results,
    :ec8a_serial_number, :presiding_officer_name,
    :result_sheet_complete, :agent_signatures_present, :presiding_officer_signed
  ]

  schema "election_result_report" do
    field :uuids, :string
    field :user_id, :integer
    field :election_type, :string
    field :election_name, :string
    field :election_form, :string
    field :pu, :string
    field :pu_id, :integer
    field :ward_id, :integer
    field :lg_id, :integer
    field :state_id, :integer
    field :ward, :string
    field :lg, :string
    field :states, :string
    field :results, :map, default: %{}
    field :image_url, :string
    field :variables, :map, default: %{}

    timestamps(type: :utc_datetime, inserted_at: :created_at, updated_at: :updated_at)
  end

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [
      :uuids, :user_id, :election_type, :election_name, :election_form,
      :pu, :ward, :lg, :states,
      :pu_id, :ward_id, :lg_id, :state_id,
      :results, :image_url, :variables
    ])
    |> validate_required([:uuids, :user_id, :election_type])
  end

  @doc """
  Returns `%{user_id => [report, ...]}` (newest first) for the given users,
  limited to one form code (default "ec8a"). Other forms in the table are ignored.
  Only light columns are selected, so `results`/`variables` are not loaded.
  """
  def list_for_users(user_ids, form \\ "ec8a")

  def list_for_users([], _form), do: %{}

  def list_for_users(user_ids, form) do
    form = String.downcase(form)

    from(r in __MODULE__,
      where: r.user_id in ^user_ids,
      where: r.election_form == ^form,
      order_by: [desc: r.created_at],
      select: %{
        id: r.id,
        user_id: r.user_id,
        pu_id: r.pu_id,
        election_name: r.election_name,
        election_form: r.election_form,
        created_at: r.created_at
      }
    )
    |> Repo.all()
    |> Enum.group_by(& &1.user_id)
  end

  @doc """
  Loads one full report and returns it in the map shape `election_result_modal` expects,
  or `nil` if it doesn't exist.
  """
  def get_for_preview(id) do
    from(r in __MODULE__,
      left_join: u in User, on: u.id == r.user_id,
      where: r.id == ^id,
      select: {r, u.full_name}
    )
    |> Repo.one()
    |> case do
      nil -> nil
      {report, user_name} -> to_preview(report, user_name)
    end
  end

  defp to_preview(%__MODULE__{} = r, user_name) do
    results = r.results || %{}

    base =
      Map.new(@result_keys, fn key -> {key, Map.get(results, Atom.to_string(key))} end)

    Map.merge(base, %{
      id: r.id,
      user_id: r.user_id,
      user_name: user_name,
      election_name: r.election_name,
      election_type: r.election_type,
      election_form: r.election_form,
      upload_url: r.image_url,
      # +1h so the modal matches the WAT times shown in the officers list
      inserted_at: r.created_at && DateTime.add(r.created_at, 3600, :second),
      variables: r.variables || %{},
      # fall back to the plain columns if the results map lacks a name
      polling_unit: base.polling_unit || r.pu,
      ward: base.ward || r.ward,
      local_government: base.local_government || r.lg,
      state: base.state || r.states
    })
  end
end
