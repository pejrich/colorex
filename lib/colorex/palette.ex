defmodule Colorex.Palette do
  @moduledoc """
  Functions for working with or generating palettes of colors.
  """
  import Colorex.Macros
  import Colorex.Convert
  import Colorex, only: [update: 3]

  @palettes Colorex.Support.parse_tsv(:code.priv_dir(:colorex) |> Path.join("color_palettes.tsv"))
  @doc false
  def raw_palette_data, do: @palettes

  @doc """
    Generates N color palettes.

    Pass in how many color palettes you want to see.

    The optional second argument(pass in any string) is used to generate an offset so you can get some new color palettes.

    Pass the result into `display_palettes/2` for a better viewing of the color palettes

  ## Examples:

  ```
  iex> Colorex.Palette.get_palettes(2, "random string")
  [
    [Colorex.parse!("#CADDEC"), Colorex.parse!("#5F8CC0"), Colorex.parse!("#143D86"), Colorex.parse!("#F2F2DF")],
    [Colorex.parse!("#8978AF"), Colorex.parse!("#FCA0A2"), Colorex.parse!("#FCC4C6"), Colorex.parse!("#367E72")]
  ]
  ```
  """
  @spec get_palettes(n :: pos_integer(), seed :: String.t()) :: list(list(Colorex.Color.t()))
  def get_palettes(n, seed \\ "") when is_binary(seed) do
    offset = :erlang.crc32(seed) |> rem(length(raw_palette_data()))

    Enum.drop(raw_palette_data(), offset)
    |> Enum.take(n)
    |> Enum.map(fn row ->
      Enum.map(row, &Colorex.parse!/1)
    end)
  end

  @doc """
    Displays a list of color palettes

    The default inspecting of the color palettes from `get_palettes/2` isn't the easiest to see the colors.

    Pass in the results from `get_palettes/2` and see each color palette printing in a row.

    The optional second argument is the size of each color square.

    Requires a terminal that supports truecolor/24-bit color.
  """
  def display_palettes(list, size \\ 2) do
    Enum.each(list, fn row -> Colorex.Utils.print_swatches(row, size) end)
  end

  @doc """
    Returns n color(s) between the input colors

    Returns a list of colors that bridge the gap between the two input colors.

    N does not include the input colors, so if you want a total of 10 colors, you would call this function with n equal to 8.

    ## Examples:

    ```
    iex> Colorex.between(Colorex.parse!("#3355FF"), Colorex.parse!("#C27E70"), 4)
    [Colorex.parse!("#3FE1F3"),
     Colorex.parse!("#4BE785"),
     Colorex.parse!("#87DA58"),
     Colorex.parse!("#CEC464")]
    ```
  """
  cdef between(color1 :: :hsl, color2 :: :hsl, n \\ 1) do
    for i <- n..1 do
      light = color2.lightness + (color1.lightness - color2.lightness) / (n + 1) * i
      sat = color2.saturation + (color1.saturation - color2.saturation) / (n + 1) * i
      hue = color2.hue + (color1.hue - color2.hue) / (n + 1) * i
      alpha = color2.alpha + (color1.alpha - color2.alpha) / (n + 1) * i
      {hue, light, sat}
      %Colorex.HSL{hue: hue, lightness: light, saturation: sat, alpha: alpha}
    end
  end

  @doc """
    Returns the complement of a color in HSL colorspace.

    ## Examples:

    ```
    iex> Colorex.complement(Colorex.parse!("#3355FF"))
    Colorex.parse!("#FFDD33")
    ```
  """
  @spec complement(color :: Colorex.Colorex.color()) :: Colorex.Colorex.color()
  def complement(color) do
    update(color, :hue, &(&1 + 180))
  end

  @doc """
    Returns analogous colors for the input color

    returns a tuple of two colors that are N degrees(default 30°) away

    ## Example:
    ```
    iex> Colorex.analogous(Colorex.parse!("#3355FF"))
    {Colorex.parse!("#33BBFF"), Colorex.parse!("#7733FF")}
    ```
  """
  @spec analogous(color :: Colorex.Colorex.color(), degrees :: pos_integer()) ::
          {Colorex.color(), Colorex.color()}
  def analogous(color, degrees \\ 30),
    do: {update(color, :hue, &(&1 - degrees)), update(color, :hue, &(&1 + degrees))}

  @doc """
    Returns triadic colors for the input color

    returns a tuple of two colors that are N degrees(default 120°) away

    ## Examples:
    ```
    iex> Colorex.triadic(Colorex.parse!("#3355FF"))
    {Colorex.parse!("#55FF33"), Colorex.parse!("#FF3355")}
    ```
  """
  @spec triadic(color :: Colorex.Colorex.color(), degrees :: pos_integer()) ::
          {Colorex.color(), Colorex.color()}
  def triadic(color, degrees \\ 120), do: analogous(color, degrees)

  @doc """
    Returns tetradic colors for the input color

    returns a tuple of three colors that are 90°, 180°, and 270° away from the input color.

    ## Examples:

    ```
    iex> Colorex.tetradic(Colorex.parse!("#3355FF"))
    {Colorex.parse!("#FF33BB"), Colorex.parse!("#FFDD33"), Colorex.parse!("#33FF77")}
    ```
  """
  @spec tetradic(color :: Colorex.Colorex.color()) ::
          {Colorex.color(), Colorex.color(), Colorex.color()}
  def tetradic(color) do
    {update(color, :hue, &(&1 + 90)), update(color, :hue, &(&1 + 180)),
     update(color, :hue, &(&1 - 90))}
  end
end
