defmodule PhillyBands.EventsTest do
  use PhillyBands.DataCase

  alias PhillyBands.Events
  import PhillyBands.EventsFixtures

  describe "events" do
    alias PhillyBands.Events.Event

    @invalid_attrs %{date: nil, external_artist: nil, external_link: nil, region: nil, venue: nil}

    test "list_events/0 returns all events" do
      event = event_fixture()
      assert Events.list_events() == [event]
    end

    test "get_event!/1 returns the event with given id" do
      event = event_fixture()
      assert Events.get_event!(event.id) == event
    end

    test "create_event/1 with valid data creates a event" do
      valid_attrs = %{
        date: ~N[2026-01-09 00:00:00],
        external_artist: "some external_artist",
        external_link: "some external_link",
        region: "some region",
        venue: "some venue"
      }

      assert {:ok, %Event{} = event} = Events.create_event(valid_attrs)
      assert event.date == ~N[2026-01-09 00:00:00]
      assert event.external_artist == "some external_artist"
      assert event.external_link == "some external_link"
      assert event.region == "some region"
      assert event.venue == "some venue"
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_event(@invalid_attrs)
    end

    test "update_event/2 with valid data updates the event" do
      event = event_fixture()

      update_attrs = %{
        date: ~N[2026-01-10 00:00:00],
        external_artist: "some updated external_artist",
        external_link: "some updated external_link",
        region: "some updated region",
        venue: "some updated venue"
      }

      assert {:ok, %Event{} = event} = Events.update_event(event, update_attrs)
      assert event.date == ~N[2026-01-10 00:00:00]
      assert event.external_artist == "some updated external_artist"
      assert event.external_link == "some updated external_link"
      assert event.region == "some updated region"
      assert event.venue == "some updated venue"
    end

    test "update_event/2 with invalid data returns error changeset" do
      event = event_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_event(event, @invalid_attrs)
      assert event == Events.get_event!(event.id)
    end

    test "delete_event/1 deletes the event" do
      event = event_fixture()
      assert {:ok, %Event{}} = Events.delete_event(event)
      assert_raise Ecto.NoResultsError, fn -> Events.get_event!(event.id) end
    end

    test "change_event/1 returns a event changeset" do
      event = event_fixture()
      assert %Ecto.Changeset{} = Events.change_event(event)
    end

    test "upsert_event/1 inserts a new event" do
      attrs = valid_event_attributes()
      assert {:ok, %Event{} = event} = Events.upsert_event(attrs)
      assert event.external_artist == attrs.external_artist
    end

    test "upsert_event/1 returns existing event if it already exists" do
      event = event_fixture()

      attrs = %{
        external_artist: event.external_artist,
        venue: event.venue,
        date: event.date,
        region: "Different Region",
        external_link: "Different Link"
      }

      assert {:ok, %Event{} = upserted_event} = Events.upsert_event(attrs)
      assert upserted_event.id == event.id
      # Should not have updated
      assert upserted_event.region == event.region
    end
  end
end
