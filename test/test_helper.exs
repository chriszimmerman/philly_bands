ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(PhillyBands.Repo, :manual)
Mox.defmock(PhillyBands.HTTPClientMock, for: PhillyBands.HTTPClient)
