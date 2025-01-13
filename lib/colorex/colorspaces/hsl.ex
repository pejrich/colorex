defmodule Colorex.HSL do
  @moduledoc """
  Struct that represents a color in the HSL colorspace
  """

  use Colorex.Colorspace
  @derive Jason.Encoder
  defstruct [
    # 0-360 (degrees)
    hue: 0,
    # 0-1 (percent)
    saturation: 0.0,
    # 0-1 (percent)
    lightness: 0.0,
    # 0-1 (percent)
    alpha: 1.0
  ]

  @typedoc """
    A representation of a color in hue, saturation, lightness and alpha.
  """
  @type t :: %__MODULE__{
          hue: pos_integer,
          saturation: float,
          lightness: float,
          alpha: float
        }


  @doc false
  def new(h, s, l, a), do: %__MODULE__{hue: h, saturation: s, lightness: l, alpha: a} |> cast()

  @doc false
  @impl true
  def to_rgba(%__MODULE__{hue: h, saturation: s, lightness: l, alpha: a}) do
    h = h / 360

    m2 =
      if l <= 0.5,
        do: l * (s + 1),
        else: l + s - l * s

    m1 = l * 2 - m2
    r = hue_to_rgb(m1, m2, h + 1 / 3)
    g = hue_to_rgb(m1, m2, h)
    b = hue_to_rgb(m1, m2, h - 1 / 3)
    rgba_tuple!(round(r * 255), round(g * 255), round(b * 255), a)
  end

  defp hue_to_rgb(m1, m2, h) do
    h = if h < 0, do: h + 1, else: h
    h = if h > 1, do: h - 1, else: h

    case h do
      h when h * 6 < 1 -> m1 + (m2 - m1) * h * 6
      h when h * 2 < 1 -> m2
      h when h * 3 < 2 -> m1 + (m2 - m1) * (2 / 3 - h) * 6
      _ -> m1
    end
  end

  @doc false
  @impl true
  def from_rgba({r, g, b, a} = tuple) when is_rgba_tuple(tuple) do
    r = r / 255
    g = g / 255
    b = b / 255

    colors = [r, g, b]
    max_color = Enum.max(colors)
    min_color = Enum.min(colors)

    l = (max_color + min_color) / 2

    {h, s, l} =
      if max_color == min_color do
        {0.0, 0.0, l}
      else
        color_diff = max_color - min_color

        s =
          if l > 0.5,
            do: color_diff / (2 - max_color - min_color),
            else: color_diff / (max_color + min_color)

        h =
          case max_color do
            ^r when g < b -> (g - b) / color_diff + 6
            ^r -> (g - b) / color_diff
            ^g -> (b - r) / color_diff + 2
            ^b -> (r - g) / color_diff + 4
          end

        h = h / 6
        {h * 360, s, l}
      end

    %__MODULE__{hue: h, saturation: s, lightness: l, alpha: a}
  end

  @doc false
  @impl true
  def cast(%{hue: h, saturation: s, lightness: l, alpha: a}) do
    %__MODULE__{
      hue: cast(h, :hue),
      saturation: cast(s, :saturation),
      lightness: cast(l, :lightness),
      alpha: cast(a, :alpha)
    }
  end

  @doc false
  @impl true
  def min_max(:hue), do: {0, 360}
  def min_max(key) when key in [:saturation, :lightness, :alpha], do: {0.0, 1.0}

  @doc false
  @impl true
  def cast(hue, :hue) when hue < 0, do: cast(hue + 360, :hue)
  def cast(hue, :hue) when hue >= 360, do: cast(hue - 360, :hue)
  def cast(hue, :hue), do: round(hue)

  def cast(value, field) when field in [:saturation, :lightness, :alpha] do
    (value / 1)
    |> min(1.0)
    |> max(0.0)
  end

  defimpl String.Chars do
    def to_string(struct), do: struct |> Colorex.Format.HSL.to_string()
  end
end
