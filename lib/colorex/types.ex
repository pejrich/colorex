defmodule Colorex.Types do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      @type integer_0_to_255 :: pos_integer
      @type float_0_to_1 :: float()
      @type rgba_tuple :: {integer_0_to_255, integer_0_to_255, integer_0_to_255, float_0_to_1}
      @type colorspace_color ::
              Colorex.RGB.t()
              | Colorex.HSL.t()
              | Colorex.LAB.t()
              | Colorex.XYZ.t()
              | Colorex.CMYK.t()
      @type color :: Colorex.Color.t() | colorspace_color

      @type color_key ::
              :red
              | :green
              | :blue
              | :alpha
              | :hue
              | :saturation
              | :lightness
              | :l
              | :a
              | :b
              | :cyan
              | :magenta
              | :yellow
              | :black
              | :x
              | :y
              | :z
    end
  end
end
