defmodule Colorex.Format.RGB do
  @moduledoc false
  use Colorex.Format

  @impl true
  def is?("rgb(" <> _), do: true
  def is?("rgba(" <> _), do: true
  def is?(_), do: false

  @regex Regex.compile!(
           "(?<r>[0-9]{1,3}%?),?\\s*(?<g>[0-9]{1,3}%?),?\\s*(?<b>[0-9]{1,3}%?)\\s*(?<a>.*)\\)"
         )

  @impl true
  def parse("rgb(" <> str), do: _parse(str)
  def parse("rgba(" <> str), do: _parse(str)

  def _parse(str) do
    case Regex.named_captures(@regex, str) do
      %{"r" => r, "g" => g, "b" => b, "a" => a} ->
        {:ok,
         Colorex.RGB.from_rgba({parse_value(r), parse_value(g), parse_value(b), parse_alpha(a)})}

      _ ->
        {:error, :invalid_rgb_format}
    end
  end

  def parse_value(val) do
    if String.ends_with?(val, "%") do
      String.trim(val, "%") |> from_int() |> Kernel./(100) |> Kernel.*(255) |> round()
    else
      from_int(val)
    end
  end

  defp parse_alpha(<<a, rest::binary>>) when a == ?, or a == ?/,
    do: parse_alpha(String.trim(rest))

  defp parse_alpha(""), do: 1.0

  defp parse_alpha(str) do
    if String.ends_with?(str, "%") do
      from_int(String.trim(str, "%")) / 100
    else
      from_float(str)
    end
  end

  @impl true
  def to_string({r, g, b, a}) do
    "rgb(#{r} #{g} #{b} / #{round(a * 100)}%)"
    |> String.replace(" / 100%", "")
  end

  def to_string(%mod{} = col), do: col |> mod.to_rgba() |> to_string()
end
