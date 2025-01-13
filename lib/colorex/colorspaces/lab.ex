defmodule Colorex.LAB do
  @moduledoc """
  Struct that represents a color in the LAB/CIELAB colorspace
  """
  use Colorex.Colorspace
  alias Colorex.XYZ
  @derive Jason.Encoder
  defstruct [:l, :a, :b, alpha: 1.0]

  @type t :: %__MODULE__{
          # 0.0..100.0
          l: float(),
          # -128.0..128.0
          a: float(),
          # -128.0..128.0
          b: float(),
          # 0.0..1.0
          alpha: float()
        }


  @doc false
  def from_rgb(%Colorex.RGB{} = rgb) do
    rgb |> Colorex.xyz() |> from_xyz()
  end

  @doc false
  @impl true
  def from_rgba(tuple) when is_rgba_tuple(tuple), do: tuple |> XYZ.from_rgba() |> from_xyz()

  @doc false
  @impl true
  def to_rgba(lab), do: lab |> to_xyz() |> XYZ.to_rgba() |> rgba_tuple!()

  @doc false
  @impl true
  def cast(%{l: l, a: a, b: b, alpha: alpha}) do
    %__MODULE__{l: cast(l, :l), a: cast(a, :a), b: cast(b, :b), alpha: cast(alpha, :alpha)}
  end

  @doc false
  @impl true
  def min_max(:l), do: {0.0, 100.0}
  def min_max(key) when key in [:a, :b], do: {-128.0, 128.0}
  def min_max(:alpha), do: {0.0, 1.0}

  @doc false
  @impl true
  def cast(l, :l), do: clamp(l / 1.0, 0.0, 100.0)
  def cast(a, key) when key in [:a, :b], do: clamp(a / 1.0, -128.0, 128.0)
  def cast(val, :alpha), do: clamp(val / 1.0, 0.0, 1.0)

  @ratio_1 216 / 24_389.0
  @ratio_2 24_389 / 27.0
  @xn 95.0489
  @yn 100.0
  @zn 108.8840

  defp from_xyz(color) do
    yr = inner_fun(color.y / @yn)
    lightness = round_channel(116 * yr - 16)
    a = round_channel(500 * (inner_fun(color.x / @xn) - yr))
    b = round_channel(200 * (yr - inner_fun(color.z / @zn)))
    %__MODULE__{l: lightness, a: a, b: b, alpha: color.alpha}
  end

  defp inner_fun(value) do
    if value < @ratio_1 do
      1 / 116.0 * (@ratio_2 * value + 16)
    else
      nth_root(value, 3)
    end
  end

  defp round_channel(channel) when is_float(channel), do: Float.round(channel, 4)

  defp nth_root(value, n, precision \\ 1.0e-5) do
    f = fn prev -> ((n - 1) * prev + value / :math.pow(prev, n - 1)) / n end
    fixed_point(f, value, precision, f.(value))
  end

  defp fixed_point(_, guess, tolerance, next)
       when abs(guess - next) < tolerance,
       do: next

  defp fixed_point(f, _, tolerance, next) do
    fixed_point(f, next, tolerance, f.(next))
  end

  defp to_xyz(%{l: l, a: a, b: b}) do
    y = (l + 16) / 116
    x = a / 500 + y
    z = y - b / 200

    [x, y, z] =
      Enum.map([x, y, z], fn v ->
        if v ** 3 > 0.008856, do: v ** 3, else: (v - 16 / 116) / 7.787
      end)

    x = x * 95.047
    y = y * 100
    z = z * 108.883
    %Colorex.XYZ{x: x, y: y, z: z}
  end

  defimpl String.Chars do
    def to_string(struct), do: struct |> Colorex.LAB.to_rgba() |> Colorex.Format.Hex.to_string()
  end
end
