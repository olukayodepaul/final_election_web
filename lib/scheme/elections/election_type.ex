# lib/web_api_election/elections/election_type.ex
defmodule WebApiElection.Elections.ElectionType do
  use Ecto.Schema

  schema "election_types" do
    field :election_id_1, :integer
    field :election_id_2, :integer
  end
end
