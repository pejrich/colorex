defmodule Colorex.CMYK do
  @moduledoc """
  Struct that represents a color in the CMYK colorspace.
  """
  use Colorex.Colorspace

  @type t :: %__MODULE__{
          cyan: float(),
          magenta: float(),
          yellow: float(),
          black: float(),
          alpha: float()
        }
  defstruct cyan: 0,
            magenta: 0,
            yellow: 0,
            black: 0,
            alpha: 1.0

  @doc false
  @impl true
  def from_rgba({r, g, b, a} = tuple) when is_rgba_tuple(tuple) do
    {r, g, b} = {r / 255, g / 255, b / 255}
    k = 1 - Enum.max([r, g, b])

    {c, m, y} =
      if k == 1 do
        {0, 0, 0}
      else
        c = (1 - r - k) / (1 - k)
        m = (1 - g - k) / (1 - k)
        y = (1 - b - k) / (1 - k)
        {c, m, y}
      end

    %__MODULE__{cyan: c, magenta: m, yellow: y, black: k, alpha: a}
  end

  @doc false
  @impl true
  def to_rgba(%{cyan: c, magenta: m, yellow: y, black: k, alpha: a}) do
    r = 255 * (1 - c) * (1 - k)
    g = 255 * (1 - m) * (1 - k)
    b = 255 * (1 - y) * (1 - k)
    rgba_tuple!(r, g, b, a)
  end

  @doc false
  @impl true
  def cast(%__MODULE__{cyan: c, magenta: m, yellow: y, black: k, alpha: alpha}) do
    %__MODULE__{
      cyan: cast(c, :cyan),
      magenta: cast(m, :magenta),
      yellow: cast(y, :yellow),
      black: cast(k, :black),
      alpha: cast(alpha, :alpha)
    }
  end

  @doc false
  @impl true
  def cast(val, key) when key in [:cyan, :magenta, :yellow, :black, :alpha], do: clamp(val / 1, 0.0, 1.0)

  @doc false
  @impl true
  def min_max(key) when key in [:cyan, :magenta, :yellow, :black, :alpha], do: {0.0, 1.0}

  defimpl String.Chars do
    def to_string(struct), do: struct |> Colorex.CMYK.to_rgba() |> Colorex.Format.Hex.to_string()
  end
end
