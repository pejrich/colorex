defmodule Colorex.Format do
  @moduledoc false
  @callback is?(String.t()) :: boolean
  @callback parse(String.t()) :: {:ok, Colorex.Colorspace.t()}
  @callback to_string(Colorex.Colorspace.t()) :: String.t()
  # @formats [:hex24, :hex32, :hsl, :rgb, :colorset, :color_literal]
  defmacro __using__(_) do
    quote do
      @behaviour Colorex.Format

      alias Colorex.{RGB, HSL}
      import Colorex.{Support, Support.Guards}
      import Kernel, except: [to_string: 1]
    end
  end

  @formats [
    hex: __MODULE__.Hex,
    hsl: __MODULE__.HSL,
    hsla: __MODULE__.HSL,
    rgb: __MODULE__.RGB,
    rgba: __MODULE__.RGB,
    hex24: __MODULE__.Hex24,
    hex32: __MODULE__.Hex32
  ]
  @format_mods Keyword.values(@formats) |> Enum.uniq()
  Enum.each(@formats, fn {k, _} ->
    def unquote(:"#{k}")(), do: get(unquote(k))
  end)

  def get(atom), do: Keyword.get(@formats, atom)

  def detect("" <> str) do
    trim = String.trim(str)

    case Enum.find(@format_mods, & &1.is?(trim)) do
      nil -> {:error, :invalid_format}
      fmt -> {:ok, fmt}
    end
  end

  # defmodule LAB do
  #   import Kernel, except: [to_string: 1]
  #   def is?("lab(" <> _), do: true
  #
  #   @regex Regex.compile!(
  #            "(?<l>[0-9]{1,3}%?),?\\s*(?<a>-?[0-9]{1,3}%?),?\\s*(?<b>-?[0-9]{1,3}%?),?\\s*(?<alpha>.*)\\)"
  #          )
  #   def parse("lab(" <> str) do
  #     case Regex.named_captures(@regex, str) do
  #       %{"l" => l, "a" => a, "b" => b, "alpha" => alpha} ->
  #         {:ok,
  #          Colorex.RGB.rgb(
  #            parse_value(l, 100),
  #            parse_value(a, 125, true),
  #            parse_value(b, 125, true),
  #            parse_alpha(alpha)
  #          )}
  #
  #       _ ->
  #         {:error, :invalid_rgb_format}
  #     end
  #   end
  #
  #   def parse_value(str, max, negative? \\ false)
  #   def parse_value("-" <> str, max, true), do: -1 * parse_value(str, max, false)
  #
  #   def parse_value(val, max, false) do
  #     if String.ends_with?(val, "%") do
  #       String.trim(val, "%") |> from_int() |> Kernel./(100) |> Kernel.*(max) |> round()
  #     else
  #       from_int(val)
  #     end
  #   end
  #
  #   defp parse_alpha(<<a, rest::binary>>) when a == ?, or a == ?/,
  #     do: parse_alpha(String.trim(rest))
  #
  #   defp parse_alpha(""), do: 1.0
  #
  #   defp parse_alpha(str) do
  #     if String.ends_with?(str, "%") do
  #       from_int(String.trim(str, "%")) / 100
  #     else
  #       from_float(str)
  #     end
  #   end
  #
  #   def to_string({r, g, b, a}) do
  #     "rgb(#{r} #{g} #{b} / #{round(a * 100)}%)"
  #     |> String.replace(" / 100%", "")
  #   end
  #
  #   def to_string(%mod{} = col), do: col |> mod.to_rgba() |> to_string()
  # end
end
