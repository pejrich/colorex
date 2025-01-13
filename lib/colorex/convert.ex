defmodule Colorex.Convert do
  @moduledoc false
  import Colorex.Support.Guards
  alias Colorex.{RGB, HSL, LAB, XYZ, CMYK}
  use Colorex.Types

  @spec rgba_tuple(color()) :: rgba_tuple()
  def rgba_tuple(tuple) when is_rgba_tuple(tuple), do: tuple
  def rgba_tuple(%Colorex.Color{color: color}), do: rgba_tuple(color)
  def rgba_tuple(%mod{} = color), do: mod.to_rgba(color)

  @spec rgb(color()) :: RGB.t()
  def rgb(%Colorex.Color{color: color}), do: rgb(color)
  def rgb(%RGB{} = rgb), do: rgb
  def rgb(%mod{} = color), do: color |> mod.to_rgba() |> rgb()
  def rgb(rgba) when is_rgba_tuple(rgba), do: rgba |> RGB.from_rgba()

  @spec hsl(color()) :: HSL.t()
  def hsl(%Colorex.Color{color: color}), do: hsl(color)
  def hsl(%HSL{} = hsl), do: hsl
  def hsl(%mod{} = color), do: color |> mod.to_rgba() |> hsl()
  def hsl(rgba) when is_rgba_tuple(rgba), do: rgba |> HSL.from_rgba()

  @spec cmyk(color()) :: CMYK.t()
  def cmyk(%CMYK{} = cmyk), do: cmyk
  def cmyk(%Colorex.Color{color: color}), do: cmyk(color)
  def cmyk(%mod{} = color), do: color |> mod.to_rgba() |> cmyk()
  def cmyk(rgba) when is_rgba_tuple(rgba), do: rgba |> CMYK.from_rgba()

  @spec lab(color()) :: LAB.t()
  def lab(%Colorex.Color{color: color}), do: lab(color)
  def lab(%LAB{} = lab), do: lab
  def lab(%mod{} = color), do: color |> mod.to_rgba() |> lab()
  def lab(rgba) when is_rgba_tuple(rgba), do: rgba |> LAB.from_rgba()

  @spec xyz(color()) :: XYZ.t()
  def xyz(%Colorex.Color{color: color}), do: xyz(color)
  def xyz(%XYZ{} = xyz), do: xyz
  def xyz(%mod{} = color), do: color |> mod.to_rgba() |> xyz()
  def xyz(rgba) when is_rgba_tuple(rgba), do: rgba |> XYZ.from_rgba()

  @spec to_colorspace(color :: color(), :rgb | :hsl | :cmyk | :lab | :xyz) ::
          color()
  Enum.each([:rgb, :xyz, :lab, :cmyk, :hsl], fn val ->
    def to_colorspace(color, unquote(val)), do: apply(Colorex, unquote(val), [color])
  end)
end
