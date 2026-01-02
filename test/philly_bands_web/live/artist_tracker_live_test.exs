defmodule PhillyBandsWeb.ArtistTrackerLiveTest do
  use PhillyBandsWeb.ConnCase
  import Phoenix.LiveViewTest
  import PhillyBands.AccountsFixtures

  describe "Artist tracker page" do
    test "requires authentication", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log_in"}}} = live(conn, ~p"/artist_tracker")
    end

    test "allows adding and deleting artists", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/artist_tracker")

      lv
      |> form("#tracking-form", tracking: %{artist: "Green Day"})
      |> render_submit()

      assert render(lv) =~ "Green Day"
      
      # Check if the input is cleared
      assert lv |> element("#tracking-form input[name=\"tracking[artist]\"]") |> render() =~ "value=\"\"" or
             not (lv |> element("#tracking-form input[name=\"tracking[artist]\"]") |> render() =~ "value=")

      lv |> element("button", "Remove Green Day") |> render_click()
      
      # The artist should no longer be in the list of badges
      refute lv |> has_element?("span", "Green Day")
    end

    test "lists artists alphabetically", %{conn: conn} do
      user = user_fixture()
      tracking_fixture(user_id: user.id, artist: "Zebra")
      tracking_fixture(user_id: user.id, artist: "Apple")

      conn = log_in_user(conn, user)
      {:ok, _lv, html} = live(conn, ~p"/artist_tracker")

      assert html =~ ~r/Apple.*Zebra/s
    end
  end
end
