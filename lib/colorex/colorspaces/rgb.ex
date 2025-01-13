defmodule Colorex.RGB do
  @moduledoc """
  Struct that represents a color in the RGB colorspace
  """
  use Colorex.Colorspace
  @derive Jason.Encoder
  defstruct [
    # 0-255
    red: 0,
    # 0-255
    green: 0,
    # 0-255
    blue: 0,
    # 0-1
    alpha: 1.0
  ]

  @typedoc """
    A representation of a color in red, green, blue and alpha.
  """
  @type t :: %__MODULE__{
          red: :pos_integer,
          green: :pos_integer,
          blue: :pos_integer,
          alpha: :float
        }

  @doc false
  @impl true
  def to_rgba(%{red: r, green: g, blue: b, alpha: a}), do: rgba_tuple!(r, g, b, a)

  @doc false
  @impl true
  def from_rgba({r, g, b, a} = rgba) when is_rgba_tuple(rgba) do
    %__MODULE__{red: r, green: g, blue: b, alpha: a}
  end

  @doc """
    Returns R, G, and B values as percents rather than 0-255

    Example:

      iex> Colorex.parse!({51, 102, 153}) |> Colorex.rgb() |> Colorex.RGB.rgb_percents()
      {0.2, 0.4, 0.6}
  """
  def rgb_percents(%{red: r, green: g, blue: b}), do: {r / 255, g / 255, b / 255}

  @doc false
  @impl true
  def cast(%{red: r, green: g, blue: b, alpha: a}) do
    %__MODULE__{
      red: cast(r, :red),
      green: cast(g, :green),
      blue: cast(b, :blue),
      alpha: cast(a, :alpha)
    }
  end

  @doc false
  @impl true
  def min_max(key) when key in [:red, :green, :blue], do: {0, 255}
  def min_max(:alpha), do: {0.0, 1.0}

  @doc false
  @impl true
  def cast(val, :alpha), do: clamp(val, min_max(:alpha))
  def cast(val, key), do: clamp(round(val), min_max(key))

  defimpl String.Chars do
    def to_string(struct), do: Colorex.Format.RGB.to_string(struct)
  end
end
