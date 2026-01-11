defmodule PhillyBandsWeb.MyEventControllerTest do
  use PhillyBandsWeb.ConnCase
  import PhillyBands.AccountsFixtures
  import PhillyBands.EventsFixtures

  describe "index" do
    test "requires authentication", %{conn: conn} do
      conn = get(conn, ~p"/my_events")
      assert redirected_to(conn) == "/users/log_in"
    end

    test "lists events matching tracked artists (case insensitive substring)", %{conn: conn} do
      user = user_fixture()
      tracking_fixture(user_id: user.id, artist: "green day")
      tracking_fixture(user_id: user.id, artist: "The War")

      # Matches "green day" case-insensitively
      event1 = event_fixture(external_artist: "Green Day")
      # Matches "The War" substring
      event2 = event_fixture(external_artist: "The War on Drugs")
      # Does not match
      event3 = event_fixture(external_artist: "Radiohead")

      conn = log_in_user(conn, user)
      conn = get(conn, ~p"/my_events")
      response = html_response(conn, 200)

      assert response =~ "Events for My Artists"
      assert response =~ event1.external_artist
      assert response =~ event2.external_artist
      refute response =~ event3.external_artist
    end

    test "shows no events if no trackings exist", %{conn: conn} do
      user = user_fixture()
      _event = event_fixture()

      conn = log_in_user(conn, user)
      conn = get(conn, ~p"/my_events")
      response = html_response(conn, 200)

      assert response =~ "Events for My Artists"
      # Should show empty table (header/footer only)
      assert response |> Floki.parse_document!() |> Floki.find("tbody tr") |> length() == 0
    end
  end

  describe "grouping" do
    test "groups events by month", %{conn: conn} do
      user = user_fixture()
      tracking_fixture(user_id: user.id, artist: "Artist")

      event1 = event_fixture(external_artist: "Artist A", date: ~N[2026-02-09 20:00:00])
      event2 = event_fixture(external_artist: "Artist B", date: ~N[2026-03-10 20:00:00])

      conn = log_in_user(conn, user)
      conn = get(conn, ~p"/my_events")
      response = html_response(conn, 200)

      assert response =~ "February 2026"
      assert response =~ "March 2026"
      assert response =~ event1.external_artist
      assert response =~ event2.external_artist
    end
  end
end
