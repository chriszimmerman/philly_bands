defmodule PhillyBandsWeb.PageControllerTest do
  use PhillyBandsWeb.ConnCase

  import PhillyBands.AccountsFixtures
  import PhillyBands.EventsFixtures

  test "GET / as guest", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)
    assert response =~ "PhillyBands"
    assert response =~ "Discover upcoming concerts"
    assert response =~ "Get started"
  end

  test "GET / as logged in user shows my events", %{conn: conn} do
    user = user_fixture()
    tracking_fixture(user_id: user.id, artist: "Green Day")

    event_fixture(external_artist: "Green Day", date: ~N[2026-01-10 20:00:00])
    event_fixture(external_artist: "Other Artist", date: ~N[2026-01-11 20:00:00])

    conn = log_in_user(conn, user)
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ "My Upcoming Events"
    assert response =~ "Green Day"
    refute response =~ "Other Artist"
  end

  test "GET / as logged in user shows no events message", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)

    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ "My Upcoming Events"
    assert response =~ "No upcoming events found for your tracked artists"
  end
end
