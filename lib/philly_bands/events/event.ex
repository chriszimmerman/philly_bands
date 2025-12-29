defmodule PhillyBands.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :date, :naive_datetime
    field :external_artist, :string
    field :external_link, :string
    field :region, :string
    field :venue, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:external_artist, :venue, :region, :date, :external_link])
    |> validate_required([:external_artist, :venue, :date])
  end
end
