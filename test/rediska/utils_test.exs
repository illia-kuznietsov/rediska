defmodule Rediska.UtilsTest do
  use ExUnit.Case, async: true
  import Mox
  alias Rediska.Utils

  setup do
    Mox.verify_on_exit!()

    stub(Rediska.MockRedix, :command, fn
      :redis, ["KEYS", "*"] -> {:ok, ["key1", "key2"]}
      :redis, ["GET", "key1"] -> {:ok, "value1"}
      :redis, ["GET", "key2"] -> {:ok, "value2"}
    end)

    :ok
  end

  test "create_item/2 stores an item if key does not exist" do
    expect(Rediska.MockRedix, :command, 2, fn
      :redis, ["KEYS", "*"] -> {:ok, []}
      :redis, ["SET", "new_key", "new_value"] -> {:ok, "OK"}
    end)

    assert Utils.create_item("new_key", "new_value") == {:ok, %{"new_key" => "new_value"}}
  end

  test "delete_item/1 deletes an existing key" do
    expect(Rediska.MockRedix, :command, 2, fn
      :redis, ["GET", "key1"] -> {:ok, "value1"}
      :redis, ["DEL", "key1"] -> {:ok, 1}
    end)

    assert Utils.delete_item("key1") ==
             {:ok, "Item {key: key1, value: value1} deleted successfully."}
  end

  test "delete_item/1 returns error if key doesn't exist" do
    expect(Rediska.MockRedix, :command, 2, fn
      :redis, ["GET", "missing_key"] -> {:ok, nil}
      :redis, ["DEL", "missing_key"] -> {:ok, 0}
    end)

    assert Utils.delete_item("missing_key") ==
             {:error, "Key does not exist at the moment of deletion."}
  end
end
