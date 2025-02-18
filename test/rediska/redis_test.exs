defmodule Rediska.RedisTest do
  use ExUnit.Case, async: true
  import Mox

  # Ensures mocks are checked on exit
  setup :verify_on_exit!

  test "set_kv/2 stores a key-value pair" do
    expect(Rediska.MockRedix, :command, fn :redis, ["SET", "foo", "bar"] -> {:ok, "OK"} end)

    assert Rediska.Redis.set_kv("foo", "bar") == {:ok, %{"foo" => "bar"}}
  end

  test "get_v/1 retrieves a stored value" do
    expect(Rediska.MockRedix, :command, fn :redis, ["GET", "foo"] -> {:ok, "bar"} end)

    assert Rediska.Redis.get_v("foo") == "bar"
  end

  test "get_keys/0 retrieves all keys" do
    expect(Rediska.MockRedix, :command, fn :redis, ["KEYS", "*"] -> {:ok, ["foo", "bar"]} end)

    assert Rediska.Redis.get_keys() == ["foo", "bar"]
  end

  test "del/1 deletes an existing key and returns its value" do
    expect(Rediska.MockRedix, :command, fn :redis, ["GET", "foo"] -> {:ok, "bar"} end)
    expect(Rediska.MockRedix, :command, fn :redis, ["DEL", "foo"] -> {:ok, 1} end)

    assert Rediska.Redis.del("foo") == {:ok, "bar"}
  end

  test "del/1 returns an error if the key does not exist" do
    expect(Rediska.MockRedix, :command, fn :redis, ["GET", "missing_key"] -> {:ok, nil} end)
    expect(Rediska.MockRedix, :command, fn :redis, ["DEL", "missing_key"] -> {:ok, 0} end)

    assert Rediska.Redis.del("missing_key") == {:error, :does_not_exist}
  end
end
