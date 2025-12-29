defmodule PhillyBandsWeb.EventController do
  use PhillyBandsWeb, :controller

  alias PhillyBands.Events

  def index(conn, params) do
    events = Events.list_events(params)
    regions = Events.list_regions()
    page = String.to_integer(params["page"] || "1")

    render(conn, :index,
      events: events,
      regions: regions,
      page: page,
      region: params["region"] || "all"
    )
  end
end
