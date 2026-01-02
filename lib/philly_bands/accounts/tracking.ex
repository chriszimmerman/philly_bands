defmodule PhillyBands.Accounts.Tracking do
  @moduledoc """
  Schema for tracking artists for a user.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "trackings" do
    field :artist, :string
    belongs_to :user, PhillyBands.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tracking, attrs) do
    tracking
    |> cast(attrs, [:artist, :user_id])
    |> validate_required([:artist, :user_id])
    |> unique_constraint([:user_id, :artist])
  end
end
