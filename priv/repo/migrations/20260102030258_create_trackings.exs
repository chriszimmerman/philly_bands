defmodule PhillyBands.Repo.Migrations.CreateTrackings do
  use Ecto.Migration

  def change do
    create table(:trackings) do
      add :artist, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:trackings, [:user_id])
  end
end
