defmodule WebApiElection.Elections.ElecCurrentStateQuery do
  alias WebApiElection.Repo
  alias WebApiElection.Elections.ElecCurrentState

  @doc """
  Updates the current-state row for a user_id, patching only the given
  fields. Existing columns not present in `attrs` are left untouched.
  """
  def upsert_state(user_id, attrs) when is_map(attrs) do
    case Repo.get_by(ElecCurrentState, user_id: user_id) do
      nil ->
        {:error, :not_found}

      existing ->
        existing
        |> ElecCurrentState.changeset(attrs)
        |> Repo.update()
    end
  end

  def update_irev(user_id, attrs) when is_map(attrs) do
    case Repo.get_by(ElecCurrentState, user_id: user_id) do
      nil ->
        {:error, :not_found}

      existing ->
        existing
        |> ElecCurrentState.irev_changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Updates only the security_present field for a user_id.
  """
  def update_security(user_id, attrs) when is_map(attrs) do
    case Repo.get_by(ElecCurrentState, user_id: user_id) do
      nil ->
        {:error, :not_found}

      existing ->
        existing
        |> ElecCurrentState.security_changeset(attrs)
        |> Repo.update()
    end
  end


  @doc """
  Updates only the security_present field for a user_id.
  """
  def update_ward_security(user_id, attrs) when is_map(attrs) do
    case Repo.get_by(ElecCurrentState, user_id: user_id) do
      nil ->
        {:error, :not_found}

      existing ->
        existing
        |> ElecCurrentState.ward_changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Updates only the security_present field for a user_id.
  """
  def update_party_agent_security(user_id, attrs) when is_map(attrs) do
    case Repo.get_by(ElecCurrentState, user_id: user_id) do
      nil ->
        {:error, :not_found}

      existing ->
        existing
        |> ElecCurrentState.party_agent_changeset(attrs)
        |> Repo.update()
    end
  end




end
