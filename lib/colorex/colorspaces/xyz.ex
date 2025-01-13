defmodule Colorex.XYZ do
  @moduledoc """
  Struct that represents a color in the XYZ colorspace
  """
  use Colorex.Colorspace
  defstruct [:x, :y, :z, alpha: 1.0]
  alias Colorex.RGB
  alias Colorex.XYZ

  @type t :: %__MODULE__{
    x: float(),
    y: float(),
    z: float(),
    alpha: float()
  }

  @doc false
  def from_rgb(%RGB{} = color) do
    {red_ratio, green_ratio, blue_ratio} = RGB.rgb_percents(color)
    red_ratio = fix_ratio(red_ratio)
    green_ratio = fix_ratio(green_ratio)
    blue_ratio = fix_ratio(blue_ratio)
    x = calc_x(red_ratio, green_ratio, blue_ratio)
    y = calc_y(red_ratio, green_ratio, blue_ratio)
    z = calc_z(red_ratio, green_ratio, blue_ratio)
    %XYZ{x: x, y: y, z: z, alpha: color.alpha}
  end

  @doc false
  @impl true
  def from_rgba({r, g, b, a} = tuple) when is_rgba_tuple(tuple) do
    {r, g, b} = {fix_ratio(r / 255), fix_ratio(g / 255), fix_ratio(b / 255)}

    x = calc_x(r, g, b)
    y = calc_y(r, g, b)
    z = calc_z(r, g, b)
    %XYZ{x: x, y: y, z: z, alpha: a}
  end

  @doc false
  @impl true
  def to_rgba(%{x: x, y: y, z: z, alpha: a}) do
    r = 3.2404542 * x - 1.5371385 * y - 0.4985314 * z
    g = -0.9692660 * x + 1.8760108 * y + 0.0415560 * z
    b = 0.0556434 * x - 0.2040259 * y + 1.0572252 * z
    rgba_tuple!(adj(r), adj(g), adj(b), a)
  end

  @doc false
  @impl true
  def cast(%{x: x, y: y, z: z, alpha: a}) do
    %__MODULE__{
      x: cast(x, :x),
      y: cast(y, :y),
      z: cast(z, :z),
      alpha: cast(a, :alpha)
    }
  end

  @doc false
  @impl true
  def min_max(:x), do: {0.0, 95.047}
  def min_max(:y), do: {0.0, 100.0}
  def min_max(:z), do: {0.0, 108.883}
  def min_max(:alpha), do: {0.0, 1.0}

  @doc false
  @impl true
  def cast(x, :x), do: clamp(x / 1.0, min_max(:x))
  def cast(y, :y), do: clamp(y / 1.0, min_max(:y))
  def cast(z, :z), do: clamp(z / 1.0, min_max(:z))
  def cast(a, :alpha), do: clamp(a / 1.0, min_max(:alpha))

  defp adj(c) do
    c = c / 100

    c =
      if abs(c) <= 0.0031308 do
        12.92 * c
      else
        1.055 * :math.pow(c, 1 / 2.4) - 0.055
      end

    round(c * 255)
  rescue
    _ -> 0
  end

  defp fix_ratio(ratio) do
    normalized =
      if ratio > 0.04045 do
        :math.pow((ratio + 0.055) / 1.055, 2.4)
      else
        ratio / 12.92
      end

    normalized * 100
  end

  defp calc_x(red_ratio, green_ratio, blue_ratio) do
    calc_channel(red_ratio, green_ratio, blue_ratio, 0.4124, 0.3576, 0.1805)
  end

  defp calc_y(red_ratio, green_ratio, blue_ratio) do
    calc_channel(red_ratio, green_ratio, blue_ratio, 0.2126, 0.7152, 0.0722)
  end

  defp calc_z(red_ratio, green_ratio, blue_ratio) do
    calc_channel(red_ratio, green_ratio, blue_ratio, 0.0193, 0.1192, 0.9505)
  end

  defp calc_channel(
         red_ratio,
         green_ratio,
         blue_ratio,
         red_coeff,
         green_coeff,
         blue_coeff
       ) do
    Float.round(
      red_ratio * red_coeff + green_ratio * green_coeff +
        blue_ratio * blue_coeff,
      4
    )
  end

  defimpl String.Chars do
    def to_string(struct), do: struct |> Colorex.XYZ.to_rgba() |> Colorex.Format.Hex.to_string()
  end
end
