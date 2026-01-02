defmodule PhillyBandsWeb.MyEventController do
  use PhillyBandsWeb, :controller

  alias PhillyBands.Events

  def index(conn, params) do
    user = conn.assigns.current_user
    params = Map.put(params, "user_id", user.id)
    
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
