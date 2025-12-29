defmodule PhillyBands.Events do
  @moduledoc """
  The Events context.
  """

  import Ecto.Query, warn: false
  alias PhillyBands.Repo
  alias PhillyBands.Events.Event

  def list_events do
    Event
    |> order_by([e], [asc: e.date, asc: e.external_artist])
    |> Repo.all()
  end

  def get_event!(id), do: Repo.get!(Event, id)

  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end

  def get_event_by_unique_attributes(attrs) do
    # Define what makes an event unique. 
    # For now, let's assume external_artist, venue, and date.
    # We must ensure values are not nil for Repo.get_by
    external_artist = attrs[:external_artist]
    venue = attrs[:venue]
    date = attrs[:date]

    if external_artist && venue && date do
      Repo.get_by(Event,
        external_artist: external_artist,
        venue: venue,
        date: date
      )
    else
      nil
    end
  end

  def upsert_event(attrs) do
    case get_event_by_unique_attributes(attrs) do
      nil -> create_event(attrs)
      # Already exists
      event -> {:ok, event}
    end
  end
end
