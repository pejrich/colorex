defmodule Colorex.Format.HSL do
  @moduledoc false
  use Colorex.Format
  @impl true
  def is?("hsl(" <> _), do: true
  def is?("hsla(" <> _), do: true
  def is?(_), do: false

  @regex Regex.compile!(
           "(?<h>[0-9]{1,3})(?:deg)?,?\\s*(?<s>[0-9]{1,3}%?),?\\s*(?<l>[0-9]{1,3}%?)\\s*(?<a>.*)\\)"
         )

  @impl true
  def parse("hsl(" <> str), do: _parse(str)
  def parse("hsla(" <> str), do: _parse(str)

  def _parse(str) do
    case Regex.named_captures(@regex, str) do
      %{"h" => h, "s" => s, "l" => l, "a" => a} ->
        {:ok,
         Colorex.HSL.new(
           from_pct(h),
           from_pct(s),
           from_pct(l),
           parse_alpha(a)
         )}

      _ ->
        {:error, :invalid_hsl_format}
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
  def to_string(%HSL{hue: h, saturation: s, lightness: l, alpha: a}) do
    "hsl(#{round(h)} #{round(s * 100)}% #{round(l * 100)}% / #{round(a * 100)}%)"
    |> String.replace(" / 100%", "")
  end

  def to_string(col), do: col |> Colorex.hsl() |> to_string()
end
