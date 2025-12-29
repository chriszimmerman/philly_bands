defmodule PhillyBands.Repo do
  use Ecto.Repo,
    otp_app: :philly_bands,
    adapter: Ecto.Adapters.Postgres
end
