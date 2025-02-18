defmodule Rediska.Schema do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:red_key, :string)
    field(:red_value, :string)
  end

  def changeset(item \\ %Rediska.Schema{}, attrs) do
    item
    |> cast(attrs, [:red_key, :red_value])
    |> validate_required([:red_key, :red_value])
    |> validate_change(:red_key, fn :red_key, key ->
      if key in Rediska.Redis.get_keys() do
        [red_key: {"already taken", [validation: :required]}]
      else
        []
      end
    end)
  end
end
