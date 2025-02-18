Mox.defmock(Rediska.MockRedix, for: Rediska.RedixBehaviour)
Application.put_env(:rediska, :redix, Rediska.MockRedix)

ExUnit.start()
