defmodule PhillyBandsWeb.EventControllerTest do
  use PhillyBandsWeb.ConnCase

  import PhillyBands.EventsFixtures

  describe "index" do
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
  end
end
