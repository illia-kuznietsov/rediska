defmodule Rediska.Redis do
  defp redix(), do: Application.get_env(:rediska, :redix, Redix)

  def set_kv(key, value) do
    redix().command(:redis, ["SET", key, value])
    |> case do
      {:ok, "OK"} -> {:ok, Map.new([{key, value}])}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec get_v(any()) ::
          nil
          | binary()
          | [nil | binary() | list() | integer() | Redix.Error.t()]
          | integer()
          | Redix.Error.t()
  def get_v(key) do
    redix().command(:redis, ["GET", key])
    |> case do
      {:ok, val} -> val
      {:error, reason} -> {:error, reason}
    end
  end

  def get_keys() do
    redix().command(:redis, ["KEYS", "*"])
    |> case do
      {:ok, keys} -> keys
      {:error, reason} -> {:error, reason}
    end
  end

  def del(key) do
    val = get_v(key)

    redix().command(:redis, ["DEL", key])
    |> case do
      {:ok, 1} -> {:ok, val}
      {:ok, 0} -> {:error, :does_not_exist}
      {:error, reason} -> {:error, reason}
    end
  end
end
