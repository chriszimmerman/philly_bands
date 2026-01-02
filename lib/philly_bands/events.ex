defmodule PhillyBands.Events do
  @moduledoc """
  The Events context.
  """

  import Ecto.Query, warn: false
  alias PhillyBands.Repo
  alias PhillyBands.Events.Event

  def list_events(params \\ %{}) do
    page = String.to_integer(params["page"] || "1")
    per_page = 30
    offset = (page - 1) * per_page
    region = params["region"]
    now = NaiveDateTime.local_now()

    Event
    |> filter_by_region(region)
    |> filter_by_user_trackings(params["user_id"])
    |> where([e], e.date >= ^now)
    |> order_by([e], asc: e.date, asc: e.external_artist)
    |> limit(^per_page)
    |> offset(^offset)
    |> Repo.all()
  end

  defp filter_by_region(query, nil), do: query
  defp filter_by_region(query, ""), do: query
  defp filter_by_region(query, "all"), do: query

  defp filter_by_region(query, region) do
    from e in query, where: e.region == ^region
  end

  defp filter_by_user_trackings(query, nil), do: query

  defp filter_by_user_trackings(query, user_id) do
    trackings = PhillyBands.Accounts.list_user_trackings(user_id)
    artist_names = Enum.map(trackings, & &1.artist)

    do_filter_by_artist_names(query, artist_names)
  end

  defp do_filter_by_artist_names(query, []), do: from(e in query, where: false)

  defp do_filter_by_artist_names(query, artist_names) do
    # Case insensitive substring match for any of the tracked artists
    conditions =
      Enum.reduce(artist_names, nil, fn artist, acc ->
        condition = dynamic([e], ilike(e.external_artist, ^"%#{artist}%"))

        if acc do
          dynamic([e], ^acc or ^condition)
        else
          condition
        end
      end)

    from e in query, where: ^conditions
  end

  def list_regions do
    Event
    |> where([e], not is_nil(e.region) and e.region != "")
    |> select([e], e.region)
    |> distinct(true)
    |> order_by([e], asc: e.region)
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
