defmodule PhillyBandsWeb.MyEventHTML do
  use PhillyBandsWeb, :html

  def pagination_pages(page, total_pages) do
    window_start =
      cond do
        page <= 3 -> 1
        page >= total_pages - 2 -> max(1, total_pages - 4)
        true -> page - 2
      end

    window_end = min(total_pages, window_start + 4)
    pages = Enum.to_list(window_start..window_end)
    pages = if hd(pages) == 1, do: pages, else: [1 | pages]
    pages = if List.last(pages) == total_pages, do: pages, else: pages ++ [total_pages]

    pages
    |> Enum.with_index()
    |> Enum.flat_map(fn {page, index} ->
      next_page = Enum.at(pages, index + 1)

      [page] ++ if(next_page && next_page - page > 1, do: [:ellipsis], else: [])
    end)
  end

  embed_templates "my_event_html/*"
end
