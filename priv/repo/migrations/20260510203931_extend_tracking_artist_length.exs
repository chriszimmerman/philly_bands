defmodule PhillyBands.Repo.Migrations.ExtendTrackingArtistLength do
  use Ecto.Migration

  def change do
    alter table(:trackings) do
      modify :artist, :text
    end
  end
end
