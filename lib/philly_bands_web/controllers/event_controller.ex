defmodule PhillyBandsWeb.EventController do
  use PhillyBandsWeb, :controller

  alias PhillyBands.Events

  def index(conn, _params) do
    events = Events.list_events()
    render(conn, :index, events: events)
  end
end
