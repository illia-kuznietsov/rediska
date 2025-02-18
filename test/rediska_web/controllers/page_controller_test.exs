defmodule RediskaWeb.PageControllerTest do
  use RediskaWeb.ConnCase
  import Mox, only: [stub: 3]

  setup do
    Mox.verify_on_exit!()

    stub(Rediska.MockRedix, :command, fn
      :redis, ["KEYS", "*"] -> {:ok, ["foo", "bar"]}
      :redis, ["GET", _key] -> {:ok, nil}
    end)

    :ok
  end

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Rediska."
  end
end
