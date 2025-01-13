defmodule Colorex.Parser do
  @moduledoc false
  import Colorex.{Support, Support.Guards}

  @path :code.priv_dir(:colorex) |> Path.join("named_colors.tsv")
  @external_resource @path
  @named_colors parse_tsv(@path)
                |> Enum.map(fn [_, k, v, _] -> {k, v} end)
                |> Enum.into(%{})
  def named_colors, do: @named_colors

  def parse!(input) do
    {:ok, color} = parse(input)
    color
  end

  def parse(tuple) when is_rgba_tuple(tuple),
    do:
      {:ok, %Colorex.Color{color: Colorex.RGB.from_rgba(tuple), format: Colorex.Format.get(:hex)}}

  def parse({r, g, b}), do: parse({r, g, b, 1.0})
  def parse({r, g, b, a}) when is_integer(a), do: parse({r, g, b, a / 255})

  def parse({r, g, b, a})
      when is_float(r) and is_float(g) and is_float(b) and r >= 0.0 and r <= 1.0 and g >= 0.0 and
             g <= 1.0 and b >= 0.0 and b <= 1.0 do
    # handle pct rgba format: {0.56, 0.23, 1.0, 1.0}
    parse({round(r * 255), round(g * 255), round(b * 255), a})
  end

  def parse(input) do
    with input <- Map.get(@named_colors, input, input),
         {:ok, format} <- Colorex.Format.detect(input),
         {:ok, color} <- format.parse(input) do
      {:ok, %Colorex.Color{color: color, format: format}}
    end
  end
end
