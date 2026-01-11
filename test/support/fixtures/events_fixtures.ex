defmodule PhillyBands.EventsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PhillyBands.Events` context.
  """

  def unique_event_artist, do: "Artist #{System.unique_integer()}"

  def valid_event_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      external_artist: unique_event_artist(),
      venue: "The Fillmore",
      region: "Philadelphia Area",
      date: ~N[2026-02-09 20:00:00],
      external_link: "https://example.com/event"
    })
  end

  def event_fixture(attrs \\ %{}) do
    {:ok, event} =
      attrs
      |> valid_event_attributes()
      |> PhillyBands.Events.create_event()

    event
  end
end
