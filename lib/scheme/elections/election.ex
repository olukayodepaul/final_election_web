# lib/web_api_election/elections/election.ex
defmodule WebApiElection.Elections.Election do
  use Ecto.Schema

  schema "elections" do
    field :map_id,     :integer
    field :name,       :string
    field :is_active,  :boolean
    field :types,      :integer
    field :leads_type, :integer
    field :icon,       :string
    field :link,       :string
  end
end
