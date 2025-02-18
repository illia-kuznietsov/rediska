defmodule Rediska.Utils do
  alias Rediska.Schema, as: Item

  def get_items() do
    keys = Rediska.Redis.get_keys()
    values = keys |> Enum.map(&Rediska.Redis.get_v/1)
    Enum.zip(keys, values) |> Enum.map(&Map.new([&1]))
  end

  def create_item(key, value) do
    changeset = Item.changeset(%{red_key: key, red_value: value}) |> Map.put(:action, :validate)

    with [] <- changeset.errors, {:ok, item} <- Rediska.Redis.set_kv(key, value) do
      {:ok, item}
    else
      errors when is_list(errors) -> {:error, changeset}
      {:error, reason} -> {:error, reason}
    end
  end

  def update_item(item, key, value) do
    current_key = Map.keys(item) |> hd

    changeset =
      Item.changeset(%Item{red_key: current_key, red_value: item[key]}, %{
        red_key: key,
        red_value: value
      })
      |> Map.put(:action, :validate)

    with [] <- changeset.errors, {:ok, item} <- Rediska.Redis.set_kv(key, value) do
      {:ok, item}
    else
      errors when is_list(errors) -> {:error, changeset}
      {:error, reason} -> {:error, reason}
    end
  end

  def delete_item(key) do
    case Rediska.Redis.del(key) do
      {:ok, val} -> {:ok, "Item {key: #{key}, value: #{val}} deleted successfully."}
      {:error, :does_not_exist} -> {:error, "Key does not exist at the moment of deletion."}
      {:error, reason} -> {:error, reason}
    end
  end
end
