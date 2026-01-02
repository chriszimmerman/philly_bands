defmodule PhillyBands.HTTPClient do
  @moduledoc """
  Behavior for HTTP requests.
  """
  @callback request(method :: atom(), url :: String.t()) ::
              {:ok, %{status: integer(), body: String.t()}} | {:error, any()}
end

defmodule PhillyBands.HTTPClient.Finch do
  @moduledoc """
  Finch implementation of the HTTPClient behavior.
  """
  @behaviour PhillyBands.HTTPClient

  def request(:get, url) do
    Finch.build(:get, url)
    |> Finch.request(PhillyBands.Finch)
    |> case do
      {:ok, %{status: status, body: body}} -> {:ok, %{status: status, body: body}}
      {:error, reason} -> {:error, reason}
    end
  end
end
