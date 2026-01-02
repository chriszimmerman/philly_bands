defmodule PhillyBandsWeb.EventControllerTest do
  use PhillyBandsWeb.ConnCase
  use Patch

  import PhillyBands.EventsFixtures

  describe "index" do
    test "lists events with pagination", %{conn: conn} do
      for i <- 1..35 do
        event_fixture(external_artist: "Artist #{i}", date: ~N[2026-01-09 20:00:00])
      end

      conn = get(conn, ~p"/events")
      response = html_response(conn, 200)
      assert response =~ "Listing Events"
      
      # Should only show 30 events
      assert response |> Floki.parse_document!() |> Floki.find("tbody tr") |> length() == 30
      assert response =~ "Next Page"

      conn = get(conn, ~p"/events?page=2")
      response = html_response(conn, 200)
      assert response |> Floki.parse_document!() |> Floki.find("tbody tr") |> length() == 5
      assert response =~ "Previous Page"
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

    test "lists all events in order", %{conn: conn} do
      _event1 = event_fixture(external_artist: "B", date: ~N[2026-01-10 20:00:00])
      _event2 = event_fixture(external_artist: "A", date: ~N[2026-01-10 20:00:00])
      _event3 = event_fixture(external_artist: "C", date: ~N[2026-01-09 20:00:00])

      conn = get(conn, ~p"/events")
      response = html_response(conn, 200)
      assert response =~ "Listing Events"
      
      assert response =~ ~r/2026-01-09.*2026-01-10.*2026-01-10/s
      assert response =~ ~r/C.*A.*B/s
    end

    test "filters out past events", %{conn: conn} do
      # Mock current date to 2026-01-01
      Patch.patch(NaiveDateTime, :local_now, ~N[2026-01-01 12:00:00])

      future_event = event_fixture(external_artist: "Future Artist", date: ~N[2026-01-02 20:00:00])
      past_event = event_fixture(external_artist: "Past Artist", date: ~N[2025-12-31 20:00:00])

      conn = get(conn, ~p"/events")
      response = html_response(conn, 200)
      
      assert response =~ future_event.external_artist
      refute response =~ past_event.external_artist
    end
  end
end
