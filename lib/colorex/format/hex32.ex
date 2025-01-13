defmodule Colorex.Format.Hex32 do
  @moduledoc false
  use Colorex.Format
  @impl true
  def is?(" " <> str), do: is?(str)

  def is?(<<"#", r::bytes-size(2), g::bytes-size(2), b::bytes-size(2), a::bytes-size(2)>>)
      when is_hex_str(r) and is_hex_str(g) and is_hex_str(b) and is_hex_str(a),
      do: true

  def is?({r, g, b, a})
      when is_hex8_int(r) and is_hex8_int(g) and is_hex8_int(b) and is_alpha_float(a),
      do: true

  def is?(_), do: false

  @impl true
  def parse(tuple) when is_rgba_tuple(tuple), do: {:ok, RGB.from_rgba(tuple)}
  def parse(" " <> str), do: parse(str)

  def parse(<<"#", r::bytes-size(2), g::bytes-size(2), b::bytes-size(2), a::bytes-size(2)>>) do
    parse(rgba_tuple!(from_hex(r), from_hex(g), from_hex(b), from_hex(a) / 255))
  end

  @impl true
  def to_string(%RGB{} = rgb), do: RGB.to_rgba(rgb) |> to_string()

  def to_string({r, g, b, a}),
    do: "##{to_hex(r)}#{to_hex(g)}#{to_hex(b)}#{to_hex(round(a * 255))}"
end
