defmodule WebApiElection.Repo do
  use Ecto.Repo,
    otp_app: :web_api_election,
    adapter: Ecto.Adapters.Postgres
end
