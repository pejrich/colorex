defmodule Colorex.Format.Hex do
  @moduledoc false
  use Colorex.Format
  alias Colorex.Format.{Hex24, Hex32}

  @impl true
  def is?(str), do: Hex24.is?(str) || Hex32.is?(str)

  @impl true
  def parse(str), do: (Hex32.is?(str) && Hex32.parse(str)) || Hex24.parse(str)

  @impl true
  def to_string(%RGB{alpha: 1.0} = rgb), do: Hex24.to_string(rgb)
  def to_string(%RGB{} = rgb), do: Hex32.to_string(rgb |> IO.inspect())
  def to_string(color), do: Colorex.rgb(color) |> to_string()
end
