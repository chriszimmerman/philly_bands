defmodule PhillyBandsWeb.EventControllerTest do
  use PhillyBandsWeb.ConnCase
  use Patch

  import PhillyBands.EventsFixtures

  describe "index" do
    test "lists events with pagination", %{conn: conn} do
      PhillyBands.Repo.delete_all(PhillyBands.Events.Event)

      for i <- 1..35 do
        event_fixture(external_artist: "Artist #{i}", date: ~N[2026-02-09 20:00:00])
      end

      conn = get(conn, ~p"/events")
      response = html_response(conn, 200)
      assert response =~ "Listing Events"

      # Should only show 30 events
      assert response |> Floki.parse_document!() |> Floki.find("tbody tr") |> length() == 30
      assert response =~ "page=2"

      conn = get(conn, ~p"/events?page=2")
      response = html_response(conn, 200)
      assert response |> Floki.parse_document!() |> Floki.find("tbody tr") |> length() == 5
      assert response =~ "page=1"
      assert response =~ "/events?page=1&amp;region=all&amp;search="
    end

    test "filters by region", %{conn: conn} do
      event_fixture(region: "Region A", external_artist: "Artist A")
      event_fixture(region: "Region B", external_artist: "Artist B")

      conn = get(conn, ~p"/events?region=Region A")
      response = html_response(conn, 200)
      assert response =~ "Artist A"
      refute response =~ "Artist B"

      conn = get(conn, ~p"/events?region=all")
      response = html_response(conn, 200)
      assert response =~ "Artist A"
      assert response =~ "Artist B"
    end

    test "filters by search", %{conn: conn} do
      event_fixture(external_artist: "The War on Drugs", venue: "The Fillmore")
      event_fixture(external_artist: "Radiohead", venue: "Madison Square Garden")

      # Search by artist
      conn = get(conn, ~p"/events?search=war")
      response = html_response(conn, 200)
      assert response =~ "The War on Drugs"
      refute response =~ "Radiohead"

      # Search by venue (should no longer match)
      conn = get(conn, ~p"/events?search=square")
      response = html_response(conn, 200)
      refute response =~ "Radiohead"
      refute response =~ "The War on Drugs"

      # Case insensitive artist search
      conn = get(conn, ~p"/events?search=THE")
      response = html_response(conn, 200)
      assert response =~ "The War on Drugs"
    end

    test "lists all events in order", %{conn: conn} do
      _event1 = event_fixture(external_artist: "B", date: ~N[2026-02-10 20:00:00])
      _event2 = event_fixture(external_artist: "A", date: ~N[2026-02-10 20:00:00])
      _event3 = event_fixture(external_artist: "C", date: ~N[2026-02-09 20:00:00])

      conn = get(conn, ~p"/events")
      response = html_response(conn, 200)
      assert response =~ "Listing Events"

      assert response =~ ~r/2026-02-09.*2026-02-10.*2026-02-10/s
      assert response =~ ~r/C.*A.*B/s
    end

    test "filters out past events", %{conn: conn} do
      # Mock current date to 2026-01-01
      Patch.patch(NaiveDateTime, :local_now, ~N[2026-01-01 12:00:00])

      future_event =
        event_fixture(external_artist: "Future Artist", date: ~N[2026-01-02 20:00:00])

      past_event = event_fixture(external_artist: "Past Artist", date: ~N[2025-12-31 20:00:00])

      conn = get(conn, ~p"/events")
      response = html_response(conn, 200)

      assert response =~ future_event.external_artist
      refute response =~ past_event.external_artist
    end
  end
end
