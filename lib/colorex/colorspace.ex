defmodule Colorex.Colorspace do
  @moduledoc false
  @type rgba_tuple :: {pos_integer, pos_integer, pos_integer, float}
  @type t :: module()
  @callback to_rgba(color :: term()) :: rgba_tuple
  @callback from_rgba(color :: rgba_tuple) :: term()
  @callback cast(color :: term()) :: term()
  @callback cast(value :: term(), key :: :atom) :: term()
  @callback min_max(key :: atom()) :: {number(), number()}

  defmacro __using__(_) do
    quote do
      import Colorex.{Support, Support.Guards}
      @behaviour Colorex.Colorspace
    end
  end
end
