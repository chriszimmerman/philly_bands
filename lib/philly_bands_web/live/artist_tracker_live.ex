defmodule PhillyBandsWeb.ArtistTrackerLive do
  use PhillyBandsWeb, :live_view

  alias PhillyBands.Accounts
  alias PhillyBands.Accounts.Tracking

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    trackings = Accounts.list_user_trackings(user.id)
    changeset = Accounts.change_tracking(%Tracking{})

    {:ok,
     socket
     |> assign(:trackings, trackings)
     |> assign_form(changeset)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      My Tracked Artists
      <:subtitle>Manage the artists you want to track for upcoming events.</:subtitle>
    </.header>

    <div class="mt-10">
      <.simple_form for={@form} phx-submit="save" phx-change="validate" id="tracking-form">
        <.input
          field={@form[:artist]}
          type="text"
          label="Artist Name"
          placeholder="e.g. Green Day"
          required
          value={@form[:artist].value}
        />
        <:actions>
          <.button phx-disable-with="Adding...">Add Artist</.button>
        </:actions>
      </.simple_form>
    </div>

    <div class="mt-10">
      <div class="flex flex-wrap gap-2">
        <%= for {tracking, i} <- Enum.with_index(@trackings) do %>
          <% colors = [
            {"bg-indigo-100", "text-indigo-700", "ring-indigo-700/10", "hover:bg-indigo-600/20"},
            {"bg-rose-100", "text-rose-700", "ring-rose-700/10", "hover:bg-rose-600/20"},
            {"bg-emerald-100", "text-emerald-700", "ring-emerald-700/10", "hover:bg-emerald-600/20"},
            {"bg-amber-100", "text-amber-700", "ring-amber-700/10", "hover:bg-amber-600/20"},
            {"bg-sky-100", "text-sky-700", "ring-sky-700/10", "hover:bg-sky-600/20"},
            {"bg-violet-100", "text-violet-700", "ring-violet-700/10", "hover:bg-violet-600/20"}
          ]

          {bg, text, ring, hover} = Enum.at(colors, rem(i, length(colors))) %>
          <span class={[
            "inline-flex items-center gap-x-2 rounded-md px-3 py-1.5 text-base font-medium ring-1 ring-inset",
            bg,
            text,
            ring
          ]}>
            {tracking.artist}
            <button
              type="button"
              phx-click="delete"
              phx-value-id={tracking.id}
              class={[
                "group relative -mr-1 h-5 w-5 flex items-center justify-center rounded-sm",
                hover
              ]}
            >
              <span class="sr-only">Remove {tracking.artist}</span>
              <.icon name="hero-x-mark-mini" class="h-4 w-4" />
            </button>
          </span>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"tracking" => tracking_params}, socket) do
    changeset =
      %Tracking{}
      |> Accounts.change_tracking(tracking_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"tracking" => tracking_params}, socket) do
    user = socket.assigns.current_user
    tracking_params = Map.put(tracking_params, "user_id", user.id)

    case Accounts.create_tracking(tracking_params) do
      {:ok, _tracking} ->
        trackings = Accounts.list_user_trackings(user.id)

        {:noreply,
         socket
         |> assign(:trackings, trackings)
         |> assign(:form, to_form(Accounts.change_tracking(%Tracking{}), reset: true))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    tracking = Accounts.get_user_tracking!(user.id, id)

    case Accounts.delete_tracking(tracking) do
      {:ok, _} ->
        trackings = Accounts.list_user_trackings(user.id)
        {:noreply, assign(socket, :trackings, trackings)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete tracking")}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
