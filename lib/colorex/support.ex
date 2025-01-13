defmodule Colorex.Support do
  @moduledoc false
  import Colorex.Support.Guards
  def rgba_tuple!(r, g, b, a) when is_rgba_tuple({r, g, b, a}), do: {r, g, b, a}

  def rgba_tuple!(r, g, b, a),
    do: rgba_tuple!(cast(r, :rgb), cast(g, :rgb), cast(b, :rgb), cast(a, :a))

  def rgba_tuple!({r, g, b, a}), do: rgba_tuple!(r, g, b, a)

  @doc """
  parses `"FF"` or `"0xFF"` into `255`
  """
  def from_hex("0x" <> str), do: from_hex(str)
  def from_hex(<<a, b>> = s) when is_hex_char(a) and is_hex_char(b), do: String.to_integer(s, 16)
  def from_hex(<<a>> = s) when is_hex_char(a), do: String.to_integer(s, 16)

  def to_hex(val, pad \\ 2)

  def to_hex(float, pad) when is_float(float) and float >= 0.0 and float <= 1.0 do
    round(float * 255) |> to_hex(pad)
  end

  def to_hex(int, pad) when is_integer(int) do
    Integer.to_string(int, 16) |> String.pad_leading(pad, "0")
  end

  def from_int("" <> str), do: String.to_integer(str)

  def from_float("" <> s) do
    String.to_float(s)
  rescue
    _ -> String.to_integer(s)
  end

  @doc """
  parses `"55%"` and `"0.55"` into `0.55`
  """
  def from_pct(str) do
    if String.ends_with?(str, "%") do
      String.trim(str, "%") |> from_int() |> Kernel./(100)
    else
      from_float(str) / 1.0
    end
  end

  def clamp(value), do: clamp(value, 0, 255)
  def clamp(value, {min, max}), do: clamp(value, min,max)
  def clamp(value, _, max) when value > max, do: max
  def clamp(value, min, _) when value < min, do: min
  def clamp(value, _, _), do: value

  defp cast(val, :rgb) when is_number(val), do: val |> round() |> clamp()
  defp cast(val, :a) when is_number(val), do: (val / 1) |> clamp(0.0, 1.0)

  def avg(nums), do: Enum.sum(nums) / length(nums)

  def parse_tsv(path) do
    File.read!(path)
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&String.split(&1, "\t"))
  end
end
