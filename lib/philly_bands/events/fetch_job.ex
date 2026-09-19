defmodule PhillyBands.Events.FetchJob do
  @moduledoc """
  Background job to fetch events from the WXPN API and store them in the database.
  """
  use Oban.Worker, queue: :default, max_attempts: 3

  require Logger
  alias PhillyBands.Events

  @base_url "https://xpn.org/wp-json/tribe/events/v1/events"
  @per_page 30

  @impl Oban.Worker
  def perform(_job) do
    run()
  end

  def run do
    Logger.info("Starting event fetch job...")

    case fetch_all() do
      {:ok, count} ->
        Logger.info("Event fetch job completed. Processed #{count} events.")
        :ok

      {:error, reason} ->
        Logger.error("Event fetch job failed: #{reason}")
        :ok
    end
  end

  @doc """
  Fetches all events and returns the result without logging errors.
  Useful for testing or programmatic usage.
  """
  def fetch_all do
    fetch_page(1, 0)
  end

  defp fetch_page(page, acc_count) do
    Logger.info("Fetching page #{page}...")
    url = "#{@base_url}?page=#{page}&per_page=#{@per_page}&order=asc"

    case make_request(url) do
      {:ok, %{"events" => [_ | _] = events}} ->
        processed_count = process_events(events)
        fetch_page(page + 1, acc_count + processed_count)

      {:ok, %{"events" => []}} ->
        Logger.info("No more events to fetch.")
        {:ok, acc_count}

      {:error, reason} ->
        {:error, "Failed to fetch page #{page}: #{inspect(reason)}"}
    end
  end

  defp make_request(url) do
    http_client().request(:get, url)
    |> case do
         {:ok, %{status: 200, body: body}} ->
           {:ok, Jason.decode!(body)}

         {:ok, %{status: status, body: body}} when status in [400, 404] ->
           # WordPress/TEC returns 400 or 404 when the page number is out of bounds,
           # depending on version/install. Treat the known "invalid page" code as
           # end-of-pagination; anything else on a 400 is a real error, and any
           # other 404 body (no recognizable code) is also treated as "no more
           # pages" since that's the only way TEC signals it here.
           case Jason.decode(body) do
             {:ok, %{"code" => "rest_post_invalid_page_number"}} ->
               {:ok, %{"events" => []}}

             {:ok, error} when status == 400 ->
               {:error, error}

             _ ->
               {:ok, %{"events" => []}}
           end

         {:ok, %{status: status}} ->
           {:error, "Unexpected status: #{status}"}

         {:error, reason} ->
           {:error, reason}
       end
  end

  defp http_client do
    Application.get_env(:philly_bands, :http_client, PhillyBands.HTTPClient.Finch)
  end

  defp process_events(events) do
    Enum.reduce(events, 0, fn event_data, acc ->
      attrs = map_event_data(event_data)
      acc + maybe_insert_event(attrs)
    end)
  end

  defp maybe_insert_event(attrs) do
    if valid_event_attrs?(attrs) do
      case Events.upsert_event(attrs) do
        {:ok, _event} ->
          1

        {:error, changeset} ->
          Logger.error("Failed to insert event: #{inspect(changeset.errors)}")
          0
      end
    else
      Logger.debug("Skipping invalid event data: #{inspect(attrs)}")
      0
    end
  end

  defp valid_event_attrs?(attrs) do
    # Matches requirements in Event.changeset: external_artist, venue, date
    attrs[:external_artist] && attrs[:venue] && attrs[:date]
  end

  defp map_event_data(data) do
    %{
      external_artist: data["title"],
      venue: get_in(data, ["venue", "venue"]),
      region: extract_region(data),
      date: parse_date(data["start_date"]),
      external_link: data["website"] || data["url"]
    }
  end

  defp extract_region(data) do
    data["categories"]
    |> List.wrap()
    |> Enum.find(fn term -> term["taxonomy"] == "tribe_events_cat" end)
    |> case do
         nil -> nil
         term -> term["name"]
       end
  end

  defp parse_date(nil), do: nil

  defp parse_date(date_str) do
    # Replace space with T for ISO8601 compliance if needed
    date_str = String.replace(date_str, " ", "T")

    with {:error, _} <- NaiveDateTime.from_iso8601(date_str),
         {:error, _} <- NaiveDateTime.from_iso8601(date_str <> ":00"),
         {:error, _} <- parse_only_date(date_str) do
      nil
    else
      {:ok, %NaiveDateTime{} = ndt} -> ndt
      ndt when is_struct(ndt, NaiveDateTime) -> ndt
    end
  end

  defp parse_only_date(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, date} -> {:ok, NaiveDateTime.new!(date, ~T[00:00:00])}
      error -> error
    end
  end
end