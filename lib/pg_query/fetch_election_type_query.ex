defmodule WebApiElection.Elections.ElectionQuery do
  import Ecto.Query
  alias WebApiElection.Repo
  alias WebApiElection.Elections.Election

  @result_upload_type 1

  def list_by_type do
    Election
    |> where([e], e.types == ^@result_upload_type)
    |> order_by([e], asc: e.map_id)
    |> Repo.all()
  end
end
