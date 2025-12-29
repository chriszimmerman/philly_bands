defmodule PhillyBands.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :external_artist, :string
      add :venue, :string
      add :region, :string
      add :date, :naive_datetime
      add :external_link, :text

      timestamps(type: :utc_datetime)
    end
  end
end
