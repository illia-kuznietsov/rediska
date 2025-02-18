defmodule Rediska.SchemaTest do
  use ExUnit.Case, async: true
  import Mox
  alias Rediska.Schema

  setup do
    Mox.verify_on_exit!()
    :ok
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  test "changeset/2 requires red_key and red_value" do
    changeset = Schema.changeset(%Schema{}, %{})
    assert changeset.valid? == false
    assert "can't be blank" in errors_on(changeset).red_key
    assert "can't be blank" in errors_on(changeset).red_value
  end

  test "changeset/2 allows valid inputs" do
    expect(Rediska.MockRedix, :command, fn :redis, ["KEYS", "*"] -> {:ok, []} end)

    changeset = Schema.changeset(%Schema{}, %{red_key: "mykey", red_value: "myvalue"})
    assert changeset.valid?
  end

  test "changeset/2 rejects duplicate keys" do
    expect(Rediska.MockRedix, :command, fn :redis, ["KEYS", "*"] -> {:ok, ["existing_key"]} end)

    changeset = Schema.changeset(%Schema{}, %{red_key: "existing_key", red_value: "value"})
    assert "already taken" in errors_on(changeset).red_key
  end
end
