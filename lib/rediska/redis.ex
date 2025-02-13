defmodule Rediska.Redis do
  def set_kv(key, value) do
    Redix.command(:redis, ["SET", key, value])
  end

  def get_v(key) do
    Redix.command(:redis, ["GET", key])
    |> case do
      {:ok, val} -> val
    end
  end

  def get_keys() do
    Redix.command(:redis, ["KEYS", "*"])
    |> case do
      {:ok, keys} -> keys
      _ -> []
    end
  end
end
