defmodule Colorex.Format.Hex24 do
  @moduledoc false
  use Colorex.Format

  @impl true
  def is?(" " <> str), do: is?(str)

  def is?(<<"#", r::bytes-size(2), g::bytes-size(2), b::bytes-size(2)>>)
      when is_hex_str(r) and is_hex_str(g) and is_hex_str(b),
      do: true

  def is?(<<"#", r::bytes-size(1), g::bytes-size(1), b::bytes-size(1)>>)
      when is_hex_str(r) and is_hex_str(g) and is_hex_str(b),
      do: true

  def is?({r, g, b}) when is_hex8_int(r) and is_hex8_int(g) and is_hex8_int(b), do: true

  def is?(_), do: false

  @impl true
  def parse({r, g, b}), do: {:ok, RGB.from_rgba({r, g, b, 1.0})}
  def parse(" " <> str), do: parse(str)

  def parse(<<"#", r::bytes-size(2), g::bytes-size(2), b::bytes-size(2)>>) do
    parse({from_hex(r), from_hex(g), from_hex(b)})
  end

  def parse(<<"#", r::bytes-size(1), g::bytes-size(1), b::bytes-size(1)>>) do
    parse({from_hex(r <> r), from_hex(g <> g), from_hex(b <> b)})
  end

  @impl true
  def to_string(%RGB{} = rgb), do: RGB.to_rgba(rgb) |> to_string()
  def to_string({r, g, b, 1.0}), do: "##{to_hex(r)}#{to_hex(g)}#{to_hex(b)}"
end
