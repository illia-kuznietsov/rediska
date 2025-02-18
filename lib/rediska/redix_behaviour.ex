defmodule Rediska.RedixBehaviour do
  @callback command(atom(), list()) :: {:ok, any()} | {:error, any()}
end
