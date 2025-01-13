defmodule Colorex.Color do
  @moduledoc """
  Struct that represents a type opaque color. Automatically handles colorspace conversions and will keep the same color format as you used to create it.
  """
  use Colorex.Types
  defstruct [:color, :background, format: Colorex.Format.Hex]

  @typedoc """
  This struct encapsulates a color and handles it's internal colorspace representation/conversions.
  """

  @opaque t :: %__MODULE__{format: module, color: colorspace_color, background: color | nil}

  @doc false
  def new(color, format \\ Colorex.Format.Hex), do: %Colorex.Color{color: color, format: format}

  defimpl String.Chars do
    def to_string(%{format: format, color: %{} = color}),
      do: format.to_string(color)
  end

  defimpl Inspect do
    def inspect(colorex, opts) do
      reset =
        (opts.syntax_colors[:reset] || [:reset, :yellow])
        |> Enum.map_join(&apply(IO.ANSI, &1, []))

      flat = Colorex.flatten_alpha(colorex)
      text = Colorex.text_color(flat)

      Inspect.Algebra.concat([
        "Colorex.parse!(\"",
        Colorex.ANSI.ansi_background(flat),
        Colorex.ANSI.ansi(text),
        to_string(colorex),
        reset,
        "\")"
      ])
    end
  end
end
