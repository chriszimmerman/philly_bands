defmodule PhillyBands.Repo.Migrations.ExtendEventColumnLengths do
  use Ecto.Migration

  def change do
    alter table(:events) do
      modify :external_artist, :text
      modify :venue, :text
      modify :region, :text
    end
  end
end
