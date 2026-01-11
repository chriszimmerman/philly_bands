# PhillyBands

This is a Phoenix LiveView app that allows users to search for bands in the Philadelphia area.

## Setup

To setup the app locally:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Populating data in the app

There is a job that will call the API on WXPN's site and populate the database with the results. After you start the server with `iex -S mix phx.server`, run the job like this:

```elixir
PhillyBands.Events.FetchJob.run
```
