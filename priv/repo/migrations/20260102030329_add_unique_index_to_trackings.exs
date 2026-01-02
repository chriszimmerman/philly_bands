defmodule PhillyBands.Repo.Migrations.AddUniqueIndexToTrackings do
  use Ecto.Migration

  def change do
    create unique_index(:trackings, [:user_id, :artist])
  end
end
