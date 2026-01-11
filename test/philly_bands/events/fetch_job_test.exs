defmodule PhillyBands.Events.FetchJobTest do
  use PhillyBands.DataCase
  import Mox

  alias PhillyBands.Events.FetchJob
  alias PhillyBands.Events

  setup :verify_on_exit!

  @event_json %{
    "acf" => %{
      "date" => "2026-02-09 20:00:00",
      "external_artist" => "Test Artist",
      "external_link" => "https://example.com/tickets",
      "venue" => "Test Venue"
    },
    "_embedded" => %{
      "wp:term" => [
        [
          %{"name" => "Philadelphia Area", "taxonomy" => "category"}
        ]
      ]
    }
  }

  describe "run/0" do
    test "successfully fetches and inserts events" do
      # Page 1 returns one event
      PhillyBands.HTTPClientMock
      |> expect(:request, fn :get, url ->
        assert url =~ "page=1"
        {:ok, %{status: 200, body: Jason.encode!([@event_json])}}
      end)
      # Page 2 returns empty list (or 400 with invalid page number)
      |> expect(:request, fn :get, url ->
        assert url =~ "page=2"
        {:ok, %{status: 200, body: "[]"}}
      end)

      FetchJob.run()

      events = Events.list_events()
      assert length(events) == 1
      [event] = events
      assert event.external_artist == "Test Artist"
      assert event.venue == "Test Venue"
      assert event.region == "Philadelphia Area"
      assert event.date == ~N[2026-02-09 20:00:00]
    end

    test "handles pagination" do
      PhillyBands.HTTPClientMock
      |> expect(:request, fn :get, _url ->
        {:ok, %{status: 200, body: Jason.encode!([@event_json])}}
      end)
      |> expect(:request, fn :get, _url ->
        {:ok,
         %{
           status: 200,
           body:
             Jason.encode!([
               Map.put(
                 @event_json,
                 "acf",
                 Map.put(@event_json["acf"], "external_artist", "Other Artist")
               )
             ])
         }}
      end)
      |> expect(:request, fn :get, _url ->
        {:ok, %{status: 400, body: Jason.encode!(%{"code" => "rest_post_invalid_page_number"})}}
      end)

      FetchJob.run()

      events = Events.list_events()
      assert length(events) == 2
    end

    test "skips duplicates (upsert)" do
      # Insert the event once
      {:ok, _} =
        Events.create_event(%{
          external_artist: "Test Artist",
          venue: "Test Venue",
          date: ~N[2026-02-09 20:00:00]
        })

      PhillyBands.HTTPClientMock
      |> expect(:request, fn :get, _url ->
        {:ok, %{status: 200, body: Jason.encode!([@event_json])}}
      end)
      |> expect(:request, fn :get, _url ->
        {:ok, %{status: 200, body: "[]"}}
      end)

      FetchJob.run()

      events = Events.list_events()
      assert length(events) == 1
    end

    test "handles various date formats" do
      event1 = put_in(@event_json, ["acf", "date"], "2026-02-09 20:00")
      event2 = put_in(@event_json, ["acf", "date"], "2026-02-10")

      PhillyBands.HTTPClientMock
      |> expect(:request, fn :get, _url ->
        {:ok, %{status: 200, body: Jason.encode!([event1, event2])}}
      end)
      |> expect(:request, fn :get, _url ->
        {:ok, %{status: 200, body: "[]"}}
      end)

      FetchJob.run()

      events = Events.list_events() |> Enum.sort_by(& &1.date)
      assert length(events) == 2
      assert Enum.at(events, 0).date == ~N[2026-02-09 20:00:00]
      assert Enum.at(events, 1).date == ~N[2026-02-10 00:00:00]
    end

    test "handles unexpected status codes" do
      PhillyBands.HTTPClientMock
      |> expect(:request, fn :get, _url ->
        {:ok, %{status: 500, body: "Internal Server Error"}}
      end)

      assert {:error, "Failed to fetch page 1: \"Unexpected status: 500\""} = FetchJob.fetch_all()
    end

    test "handles HTTP client errors" do
      PhillyBands.HTTPClientMock
      |> expect(:request, fn :get, _url ->
        {:error, :timeout}
      end)

      assert {:error, "Failed to fetch page 1: :timeout"} = FetchJob.fetch_all()
    end

    test "handles malformed JSON" do
      PhillyBands.HTTPClientMock
      |> expect(:request, fn :get, _url ->
        {:ok, %{status: 200, body: "invalid json"}}
      end)

      # Jason.decode! will raise, which is acceptable for unexpected malformed data in this context
      # but let's see if we want to catch it. The current implementation doesn't catch it.
      assert_raise Jason.DecodeError, fn -> FetchJob.run() end
    end

    test "handles missing fields in API response" do
      # No acf, no _embedded
      malformed_event = %{"id" => 123}

      PhillyBands.HTTPClientMock
      |> expect(:request, fn :get, _url ->
        {:ok, %{status: 200, body: Jason.encode!([malformed_event])}}
      end)
      |> expect(:request, fn :get, _url ->
        {:ok, %{status: 200, body: "[]"}}
      end)

      # Should not crash, just log error because external_artist is missing
      FetchJob.run()
      assert Events.list_events() == []
    end
  end
end
