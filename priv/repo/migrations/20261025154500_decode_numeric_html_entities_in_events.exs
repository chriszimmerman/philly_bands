defmodule PhillyBands.Repo.Migrations.DecodeNumericHtmlEntitiesInEvents do
  use Ecto.Migration
  import Ecto.Query

  @fields [:external_artist, :venue, :region, :external_link]

  def up do
    %{rows: rows} =
      repo().query!("SELECT id, external_artist, venue, region, external_link FROM events")

    Enum.each(rows, fn [id | values] ->
      updates =
        @fields
        |> Enum.zip(values)
        |> Enum.reduce(%{}, fn {field, value}, acc ->
          decoded = decode_numeric_entities(value)
          if decoded == value, do: acc, else: Map.put(acc, field, decoded)
        end)

      if map_size(updates) > 0 do
        repo().update_all(from(event in "events", where: event.id == ^id), set: Map.to_list(updates))
      end
    end)
  end

  def down do
    raise "This migration cannot be reversed because the original entity representation is ambiguous"
  end

  defp decode_numeric_entities(nil), do: nil

  defp decode_numeric_entities(text) do
    Regex.replace(~r/&#(?:[xX]([0-9a-fA-F]+)|([0-9]+));/, text, fn
      _entity, hex, decimal ->
        codepoint = if hex == "", do: String.to_integer(decimal), else: String.to_integer(hex, 16)

        if codepoint <= 0x10FFFF and codepoint not in 0xD800..0xDFFF do
          <<codepoint::utf8>>
        else
          "&#{if(hex == "", do: decimal, else: "x" <> hex)};"
        end
    end)
  end
end