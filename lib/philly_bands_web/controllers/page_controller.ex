defmodule PhillyBandsWeb.PageController do
  use PhillyBandsWeb, :controller

  alias PhillyBands.Events

  def home(conn, params) do
    if user = conn.assigns[:current_user] do
      params = Map.put(params, "user_id", user.id)
      events = Events.list_events(params)

      render(conn, :home, events: events)
    else
      render(conn, :home)
    end
  end
end
