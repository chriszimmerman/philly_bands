defmodule PhillyBandsWeb.MyEventController do
  use PhillyBandsWeb, :controller

  alias PhillyBands.Events

  def index(conn, params) do
    user = conn.assigns.current_user
    params = Map.put(params, "user_id", user.id)

    events = Events.list_events(params)
    total_events = Events.count_events(params)
    regions = Events.list_regions()
    page = String.to_integer(params["page"] || "1")
    per_page = 30
    total_pages = ceil(total_events / per_page)

    render(conn, :index,
      events: events,
      regions: regions,
      page: page,
      total_pages: total_pages,
      region: params["region"] || "all"
    )
  end
end
