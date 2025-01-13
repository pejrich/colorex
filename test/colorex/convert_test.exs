defmodule Colorex.ConvertTest do
  use ExUnit.Case

  alias Colorex.{RGB, HSL, XYZ, LAB, CMYK}

  @nums [0, 50, 100, 150, 200, 255]
  @rgba for r <- @nums, g <- @nums, b <- @nums, do: {r, g, b, 1.0}

  test "rgba_tuple/1" do
    assert {255, 0, 0, 1.0} == p!("#FF0000") |> Colorex.hsl() |> Colorex.rgba_tuple()
    assert {0, 255, 0, 0.0} == p!("#00FF0000") |> Colorex.hsl() |> Colorex.rgba_tuple()
  end

  test "to_colorspace/2" do
    color = p!("#FF0000")
    assert %RGB{} = Colorex.to_colorspace(color, :rgb)
    assert %HSL{} = Colorex.to_colorspace(color, :hsl)
    assert %XYZ{} = Colorex.to_colorspace(color, :xyz)
    assert %LAB{} = Colorex.to_colorspace(color, :lab)
    assert %CMYK{} = Colorex.to_colorspace(color, :cmyk)
  end

  test "conversion test" do
    Enum.each(@rgba, fn rgba ->
      assert p!(rgba)
             |> Colorex.lab()
             |> Colorex.hsl()
             |> Colorex.xyz()
             |> Colorex.rgb()
             |> Colorex.RGB.to_rgba() ==
               rgba

      assert p!(rgba)
             |> Colorex.xyz()
             |> Colorex.cmyk()
             |> Colorex.rgb()
             |> Colorex.RGB.to_rgba() ==
               rgba

      assert p!(rgba)
             |> Colorex.hsl()
             |> Colorex.lab()
             |> Colorex.rgb()
             |> Colorex.RGB.to_rgba() ==
               rgba

      assert p!(rgba)
             |> Colorex.cmyk()
             |> Colorex.hsl()
             |> Colorex.rgb()
             |> Colorex.RGB.to_rgba() ==
               rgba
    end)
  end

  defp p!(val), do: Colorex.parse!(val)
end
