defmodule Colorex do
  import Colorex.Support
  import Colorex.Macros
  alias Colorex.{RGB, HSL, LAB, XYZ, CMYK}

  use Colorex.Types

  @moduledoc """
  This module contains functions for creating and manipulating colors.

  ## Color representations
  Colors are represented internally in any number of colorspaces: RGB, HSL, LAB, XYZ, or CMYK.
  The `Colorex.Color` struct represents a general color with an opaque(type opaque) colorspace. It will also attempt to
  preserve whatever input format you used, but may standardize the format slightly.
  ```
  iex> "#3355DD" |> Colorex.parse!() |> to_string()
  "#3355DD"
  iex> "#3355DD43" |> Colorex.parse!() |> to_string()
  "#3355DD43"
  iex> "rgba(51, 85, 221, 100%)" |> Colorex.parse!() |> to_string()
  "rgb(51 85 221)"
  iex> "rgba(51, 85, 221, 0.67)" |> Colorex.parse!() |> to_string()
  "rgb(51 85 221 / 67%)"
  iex> "hsl(228 71% 53% / 100%)" |> Colorex.parse!() |> to_string()
  "hsl(228 71% 53%)"
  iex> "hsl(228 71% 53% / 67%)" |> Colorex.parse!() |> to_string()
  "hsl(228 71% 53% / 67%)"
  ```
  You can access a specific colorspace by using the functions `rgb/1`, `hsl/1`, `lab/1`, `xyz/1`, `cmyk/1`, or `to_colorspace/2`

  In general, most functions in this module will accept any of the following structs: `Colorex.Color`, `Colorex.RGB`, `Colorex.HSL`,`Colorex.LAB`, `Colorex.XYZ`, `Colorex.CMYK`
  However since the function may use a different colorspace to do its calculation, you may get back a different colorspace, except if you pass in a `Colorex.Color` struct, the return type will also be a `Colorex.Color` struct.
  You can always explicitly cast the colorspace if you need a particular value, casting is a noop if the input is already in that colorspace.

  ```
  iex> hsl |> Colorex.update(:red, & &1 + 50) |> Colorex.hsl()
  ```

  All colorspaces contain an `alpha` channel for opacity.

  ## Parsing and printing

  Colorex can parse strings with any valid css color (hex, rgb, rgba, hsl, hsla and named colors).

  The `Colorex.Color` struct implements the `Inspect` protocol as it's internals are private. The displayed value is code that will evaluate to current struct, and also shows a sample of the color(requires using a terminal with truecolor)

  ```
  iex> Colorex.parse!("#3355DD")
  Colorex.parse!("#3355DD")
  ```
  """

  @doc """
    Parses a string into a Colorex struct

    Returns `{:ok, color}` on successful parse, or `{:error, reason}` otherwise
  """
  @spec parse(String.t()) :: {:ok, Colorex.Color.t()} | {:error, atom}
  defdelegate parse(string), to: Colorex.Parser

  @doc """
    Parses a string into a Colorex struct

    Similar to `parse/1` but throws on invalid input.
  """
  @spec parse!(String.t()) :: Colorex.Color.t()
  defdelegate parse!(string), to: Colorex.Parser

  @doc """
    Returns a 4-element tuple `{red, green, blue, alpha}`.

    red, green, and blue will be integers from 0 to 255 inclusive, alpha will be a float from 0.0 to 1.0 inclusive
  """
  @spec rgba_tuple(color :: color()) ::
          {integer_0_to_255(), integer_0_to_255(), integer_0_to_255(), float_0_to_1()}
  defdelegate rgba_tuple(color), to: Colorex.Convert

  @doc """
    Returns a `Colorex.RGB` struct which represents a color in the RGB colorspace
  """
  @spec rgb(color) :: RGB.t()
  defdelegate rgb(color), to: Colorex.Convert

  @doc """
    Returns a `Colorex.HSL` struct which represents a color in the HSL colorspace
  """
  @spec hsl(color) :: HSL.t()
  defdelegate hsl(color), to: Colorex.Convert

  @doc """
    Returns a `Colorex.CMYK` struct which represents a color in the CMYK colorspace
  """
  @spec cmyk(color) :: CMYK.t()
  defdelegate cmyk(color), to: Colorex.Convert

  @doc """
    Returns a `Colorex.LAB` struct which represents a color in the LAB colorspace
  """
  @spec lab(color) :: LAB.t()
  defdelegate lab(color), to: Colorex.Convert

  @doc """
    Returns a `Colorex.XYZ` struct which represents a color in the XYZ colorspace
  """
  @spec xyz(color) :: XYZ.t()
  defdelegate xyz(color), to: Colorex.Convert

  @doc """
    Converts any color/colorspace to the colorspace of the given atom.

    This function is basically the same as calling `rgb/1`, `hsl/1`, `xyz/1`, `lab/1`, or `cmyk/1` except you can convert by using an atom rather than calling the specific function.
  """
  @spec to_colorspace(color :: color(), :rgb | :hsl | :cmyk | :lab | :xyz) :: color()
  defdelegate to_colorspace(color, colorspace), to: Colorex.Convert

  @doc """
    Attempts to find the best color to use for displaying text on top of the given color.

    It will return a `Colorex.Color.t()` struct representing either black or white.

    If you want a different value returned, for example `"text-gray-100"` and `"text-gray-900"`, you can pass them in as options `[black: "text-gray-900", white: "text-gray-100"]`

    ## Example:

    ```
    iex> Colorex.text_color(Colorex.black())
    Colorex.parse!("#FFFFFF")
    iex> Colorex.text_color(Colorex.white(), white: "text-gray-100", black: "text-gray-900")
    "text-gray-900"
    ```
  """
  @spec text_color(color :: color(), opts :: [black: term(), white: term(), fast: boolean()]) ::
          color | term()
  def text_color(color, opts \\ [fast: true]) do
    fast = Keyword.get(opts, :fast)

    case {distance(color, Colorex.Utils.white(), fast: fast),
          distance(color, Colorex.Utils.black(), fast: fast)} do
      {white, black} when white <= black -> Keyword.get(opts, :black, Colorex.Utils.black())
      _ -> Keyword.get(opts, :white, Colorex.Utils.white())
    end
  end

  @doc """
    Calculates the distance between two colors.

    The default algorithm will convert to CIELAB colorspace and calculate the distance there.

    This is generally accepted to be one of the most accurate ways to calculate color distance, as the LAB colorspace was designed to uniformally distribute human perception of color.

    You can also pass in a `fast: true` option which will instead use a faster approximation in RGB space called "redmean". It'll typically return the same results as the LAB algorithm as long as the colors are similar.
    i.e. which of 2 reds is closest to another red. But it tends to be less accurate the more different the colors are.

    The fast distance algorithm is about 33x times faster than the LAB one(~6mil/s IPS vs ~180k/s on an M1 MBP)

    The results for both algorithms by default are normalized to return a float between 0 and 1. 0 being identical colors, and 1.0 for the most different colors.

    You can pass in the option `norm: false` if you want the raw results, but those numbers are pretty arbitrary as far as I know.
  """
  @spec distance(color :: color(), color2 :: color, opts :: [fast: boolean(), norm: boolean()]) ::
          float_0_to_1()
  def distance(a, b, opts \\ []),
    do: Colorex.Distance.distance(a, b, Keyword.merge([fast: false, norm: true], opts))

  @doc """
    Caclulate distance using the fast algorithm.

    This is an alias of `distance/3` with the options `[fast: true]`
  """
  @spec fast_distance(color :: color(), color2 :: color()) :: float_0_to_1()
  def fast_distance(a, b), do: Colorex.Distance.distance(a, b, fast: true, norm: true)

  @doc """
    This is a convenience function for  1 - `distance/3`.

    See that functions docs for a more in depth explanation

    Results with a larger score from `distance/3` are more different, and results with a larger score from this function `similarity/3` are more similar.
  """
  @spec similarity(color :: color(), color2 :: color(), opts :: [fast: boolean()]) ::
          float_0_to_1()
  def similarity(a, b, opts \\ []), do: 1 - distance(a, b, opts)

  @doc """
    Convenience function for `1 - fast_distance(color, color2)`
  """
  @spec fast_similarity(color(), color()) :: float_0_to_1()
  def fast_similarity(a, b), do: 1 - fast_distance(a, b)

  @doc """
    Returns the color in `colors` that is most similar to `color`

    Options:

    `fast`: Whether to use the faster or more accurate algorithm to compute similarity. Since the faster algorithms weakness is in more different colors, it should be fine for calculating most similar. Default `true`
  """
  @spec most_similar(color(), list(color())) :: color()
  @spec most_similar(color(), list(color()), fast: boolean()) :: color()
  def most_similar(color, colors, opts \\ [fast: true]),
    do: Enum.min_by(colors, &distance(color, &1, opts))

  @doc """
    Adjusts a color to work better against a dark background.

    Highly saturated colors tend to not look as good against a dark background.

    This function will reduce the saturation of a color.

    It will adjust relative to a color's saturation, so less saturated colors will be adjusted less than more saturated colors.
  """
  @spec darkmode(color :: color()) :: color()
  cdef darkmode(color :: :hsl) do
    %{color | saturation: cut_number_for_darkmode(color.saturation)}
  end

  defp cut_number_for_darkmode(val) when val == 0.0, do: 0

  defp cut_number_for_darkmode(number) do
    number * (1 - 10 * :math.log(number * 100) / :math.log(4) * number / 100)
  end

  @doc """
    Returns an integer 0-255 that represents how light/bright a color is.

    Black returns 0. White returns 255.

    This is different than just getting the HSL lightness value, as this will incorporate saturation too.

    Here is an example of some colors where sorting by `shade_number/1` and `hsl/1` lightness give the most different results. Shade number is on the top. HSL lightness on the bottom. Both sorted darkest to lightest.

    <img src="images/shade_number.png" style="width: 100%;" />
  """
  @spec shade_number(color :: color()) :: pos_integer()
  cdef shade_number(color :: :rgb) do
    %Colorex.RGB{red: red, green: green, blue: blue} = color
    :math.sqrt(0.299 * red ** 2 + 0.587 * green ** 2 + 0.114 * blue ** 2) |> round()
  end

  @doc """
    Makes a color lighter.

    Takes a color and a number between 0 and 1, and returns a color with the lightness increased by that amount.

    The given amount is a percent of the distance to be closed between the current color and white, not a fixed amount to be added. The following shows a 30%(0.3) lightening


      black   color                 white
        |-------|--------------------|
                      ^
            color after lighten(color, 0.3)

      black             color       white
        |-----------------|----------|
                             ^
                    color after lighten(color, 0.3)

      black                   color  white
        |------------------------|---|
                                  ^
                          color after lighten(color, 0.3)

    See also `darken/2` for the opposite effect.

    The function calls `update(color, :lightness, fun)`. If you want more control you can call that function directly.
  """
  @spec lighten(color :: color(), amount :: number()) :: color()
  def lighten(color, amount) do
    update(color, :lightness, fn val, {_min, max} -> val + (max - val) * amount end)
  end

  @doc """
    Makes a color darker.

    Takes a color and a number between 0 and 1, and returns a color with the lightness decreased by that amount.

    The given amount is a percent of the distance to be closed between the current color and black, not a fixed amount to be added. The following shows a 30%(0.3) darkening.


      black                color    white
        |--------------------|-------|
                      ^
                color after darken(color, 0.3)

      black       color             white
        |----------|-----------------|
               ^
          color after darken(color, 0.3)

      black color                     white
        |---|-------------------------|
          ^
      color after darken(color, 0.3)

    See also `lighten/2` for the opposite effect.

    The function calls `update(color, :lightness, fun)`. If you want more control you can call that function directly.
  """
  @spec darken(color :: color(), amount :: number()) :: color()
  def darken(color, amount) do
    update(color, :lightness, fn val, {min, _max} -> val - (val - min) * amount end)
  end

  @doc """
    Converts a color to grayscale.
  """
  @spec grayscale(color :: color()) :: color()
  def grayscale(color) do
    update(color, :saturation, fn _ -> 0.0 end)
  end

  @doc """
    Returns true if a color is grayscale

    If a color has equal Red, Green, and Blue values this will return true, else false.

    Because we may perceive colors that aren't exactly grayscale as grayscale, an optional second argument takes a threshold.

    This is a number 0 to 255 that determines how much absolute difference between R, G, B should be considered grayscale.

    Default threshold is 0, so R, G, and B must be exactly equal. A threshold of 3 would consider R:120, G:117, B:123 to be grayscale, because they're all within 3 points of the average.
  """
  @spec grayscale?(color :: color(), threshold :: integer_0_to_255()) :: boolean()
  def grayscale?(color, threshold \\ 0) do
    values = rgb(color) |> Map.take([:red, :green, :blue]) |> Map.values()
    avg = avg(values)
    Enum.all?(values, fn i -> abs(avg - i) <= threshold end)
  end

  @doc """
    Mixes two colors together.

    Specifically, takes the average of each of the RGB components, optionally weighted by the given percentage.
    The opacity of the colors is also considered when weighting the components.

    The weight specifies the amount of the first color that should be included in the returned color. The default, 0.5,
    means that half the first color and half the second color should be used. 25% means that a quarter of the first
    color and three quarters of the second color should be used.

  ## Examples:

        iex> mix(parse!("#00f"), parse!("#f00"))
        "#800080"
        iex> mix(parse!("#00f"), parse!("#f00"), 0.25)
        "#BF0040"
        iex> mix(rgb(255, 0, 0, 0.5), parse!("#00f"))
        "rgba(64, 0, 191, 0.75)"
  """
  @spec mix(color, color, number) :: color
  cdef mix(color1 :: :rgb, color2 :: :rgb, weight \\ 0.5) do
    # Algorithm taken from the sass function.

    w = weight * 2 - 1
    a = color1.alpha - color2.alpha

    w1 = (if(w * a == -1, do: w, else: (w + a) / (1 + w * a)) + 1) / 2.0
    w2 = 1 - w1

    [r, g, b] =
      [:red, :green, :blue]
      |> Enum.map(fn key ->
        round(Map.get(color1, key) * w1 + Map.get(color2, key) * w2)
      end)

    alpha = color1.alpha * weight + color2.alpha * (1 - weight)
    RGB.from_rgba(rgba_tuple!(r, g, b, alpha))
  end

  @doc """
    Color mixing using Kubelka-Munk theory / pigment mixing.

    This can often more closely resemble real-world color mixing(e.g. paint mixing).

    For example, in school you learn mixing blue and yellow gives you green. If you mix them in traditional RGB color mixing, you'll get gray, instead of green.

    `mix/3` will mix `#0000FF` and `#FFFF00` as `#808080`

    `spectral_mix/3` will mix `#0000FF` and `#FFFF00` as `#388F54`

    This function uses the algorithm from the Spectral.js Github library rather than the more popular Mixbox library, as Mixbox is not FOSS and while its source code is open, it's licensing(CC BY-NC) is too restrictive for me to include it in this library.

    In some quick tests I did, though they often both yield similar results, the Mixbox library does better overall, so if a `CC BY-NC` license works for your needs and you like this type of color mixing effect, you might want to checkout Mixbox(though no Elixir library is available to my knowledge).

    [Spectral.js - Lic: MIT](https://github.com/rvanwijnen/spectral.js)

    [Mixbox - Lic: CC BY-NC](https://github.com/scrtwpns/mixbox)

    Here is a comparison of `mix/3`(on the left) and `spectral_mix/3`(on the right).

  <div style="display: flex; flex-direction: row;">
    <div><img src="images/spectral_compare.png" style="width: 100%;" alt="spectral mixing comparison 1"/></div>
    <div><img src="images/spectral_compare2.png" style="width: 100%;" alt="spectral mixing comparison 2"/></div>
    <div><img src="images/spectral_compare3.png" style="width: 100%;" alt="spectral mixing comparison 3"/></div>
  </div>
  """
  @spec spectral_mix(color1 :: color, color2 :: color, weight :: float) :: color
  cdef spectral_mix(color :: :rgb, color2 :: :rgb, weight \\ 0.5) do
    Colorex.SpectralMix.mix(color, color2, weight)
  end

  @doc """
    Get any value from any colorspace

    This function will fetch the requested key, automatically converting colorspace if neccessary.

  ## Examples:

    ```
    iex> Colorex.parse!("#114466") |> Colorex.rgb() |> Colorex.get(:saturation)
    0.714285714285
    ```
  """
  @spec get(color :: color(), key :: color_key()) :: number()
  def get(%Colorex.Color{color: color}, key), do: get(color, key)
  def get(color, :alpha), do: color.alpha

  def get(color, key) when key in [:hue, :saturation, :lightness],
    do: Map.get(hsl(color), key)

  def get(color, key) when key in [:cyan, :magenta, :yellow, :black],
    do: Map.get(cmyk(color), key)

  def get(color, key) when key in [:x, :y, :z],
    do: Map.get(xyz(color), key)

  def get(color, key) when key in [:l, :a, :b],
    do: Map.get(lab(color), key)

  def get(color, key) when key in [:red, :green, :blue],
    do: Map.get(rgb(color), key)

  @doc """
    Set any value in any colorspace

    Allows you to set the value of the given key. Colorspace will be automatically converted if needed

  ## Examples:

    ```
    iex> Colorex.parse!("#3355DD") |> Colorex.hsl() |> Colorex.put(:red, 55) |> Colorex.put(:saturation, 0.75)
    %Colorex.HSL{
      hue: 229.1566265060241,
      saturation: 0.75,
      lightness: 0.5411764705882354,
      alpha: 1.0
    }
    ```

    If you want to set a value based on the current value, see `update/3`
  """
  @spec put(color :: color(), key :: color_key(), value :: number()) :: color()
  cdef put(color, key, value) do
    _do_put(color, key, value)
  end

  defp _do_put(color, :alpha, value), do: %{color | alpha: value}

  defp _do_put(color, key, value) when key in [:hue, :saturation, :lightness],
    do: %{hsl(color) | key => value}

  defp _do_put(color, key, value) when key in [:cyan, :magenta, :yellow, :black],
    do: %{cmyk(color) | key => value}

  defp _do_put(color, key, value) when key in [:x, :y, :z],
    do: %{xyz(color) | key => value}

  defp _do_put(color, key, value) when key in [:l, :a, :b],
    do: %{lab(color) | key => value}

  defp _do_put(color, key, value) when key in [:red, :green, :blue],
    do: %{rgb(color) | key => value}

  @doc """
    Update any attribute in any colorspace

  ## Examples:

    ```
    iex> Colorex.parse!("#3355DD") |> Colorex.update(:lightness, & &1 * 1.3) |> Colorex.update(:blue, & &1 - 40) |> Colorex.update(:hue, & &1 + 15) |> Colorex.update(:saturation, & &1 * 1.1)
    Colorex.parse!("#7579C5")
    ```

    There's also a 2-arity version which will receive `{min, max}` as the second argument.

    So the following would bring the current color halfway between it's current red value, and the max red value.

    ```
    iex> Colorex.parse!("#3355DD") |> Colorex.update(:red, fn val, {_, max} -> val + ((max - val) / 2) end)
    ```

    All values, except `hue` are clamped to their `{min, max}`.

    ```
    iex> Colorex.update(rgb_color, :red, fn _ -> 500 end) |> Map.get(:red)
    255
    iex> Colorex.update(hsl_color, :hue, fn _ -> 500 end) |> Map.get(:hue)
    140 # Hue is a 0-360 degree measurement, so 500 - 360 == 140
    ```
  """
  @spec update(color :: color, key :: color_key, fun :: (number() -> number())) :: color()
  @spec update(
          color :: color,
          key :: color_key,
          fun :: (number(), {number(), number()} -> number())
        ) :: color()
  cdef update(color, key, fun) do
    _do_update(color, key, fun)
  end

  defp _do_update(color, val, fun) when is_function(fun, 1) do
    _do_update(color, val, fn i, _ -> fun.(i) end)
  end

  defp _do_update(color, :alpha, fun),
    do: Map.update!(color, :alpha, fn val -> clamp(fun.(val, min_max(:alpha)), {0.0, 1.0}) end)

  defp _do_update(color, key, fun) when key in [:hue, :saturation, :lightness],
    do: Map.update!(hsl(color), key, fn val -> fun.(val, min_max(key)) end) |> HSL.cast()

  defp _do_update(color, key, fun) when key in [:cyan, :magenta, :yellow, :black],
    do: Map.update!(cmyk(color), key, fn val -> fun.(val, min_max(key)) end) |> CMYK.cast()

  defp _do_update(color, key, fun) when key in [:x, :y, :z],
    do: Map.update!(xyz(color), key, fn val -> fun.(val, min_max(key)) end) |> XYZ.cast()

  defp _do_update(color, key, fun) when key in [:l, :a, :b],
    do: Map.update!(lab(color), key, fn val -> fun.(val, min_max(key)) end) |> LAB.cast()

  defp _do_update(color, key, fun) when key in [:red, :green, :blue],
    do: Map.update!(rgb(color), key, fn val -> fun.(val, min_max(key)) end) |> RGB.cast()

  defp min_max(key) when key in [:red, :green, :blue, :alpha], do: RGB.min_max(key)
  defp min_max(key) when key in [:cyan, :magenta, :yellow, :black], do: CMYK.min_max(key)
  defp min_max(key) when key in [:l, :a, :b], do: LAB.min_max(key)
  defp min_max(key) when key in [:x, :y, :z], do: XYZ.min_max(key)
  defp min_max(key) when key in [:hue, :saturation, :lightness], do: HSL.min_max(key)

  @doc """
    Averages a list of colors together in the RGB colorspace.

  ## Examples:
    ```
    iex> Colorex.average([Colorex.parse!("#3355FF"), Colorex.parse!("#FF5533")])
    Colorex.parse!("#B855B8")
    ```
  """
  @spec average(list(color())) :: color()
  def average([%Colorex.Color{} = c | _] = colors), do: %{c | color: _average(colors)}
  def average(colors), do: _average(colors)

  defp _average(colors) do
    colors = Enum.map(colors, &rgb/1)

    r = Enum.map(colors, &(&1.red ** 2)) |> avg() |> :math.sqrt() |> round()
    g = Enum.map(colors, &(&1.green ** 2)) |> avg() |> :math.sqrt() |> round()
    b = Enum.map(colors, &(&1.blue ** 2)) |> avg() |> :math.sqrt() |> round()
    a = Enum.map(colors, &(&1.alpha ** 2)) |> avg() |> :math.sqrt()

    rgb({r, g, b, a})
  end

  @doc """
    Update color format of a `Colorex.Color` struct

    options: [:hex, :hex24, :hex32, :hsl, :hsla, :rgb, :rgba]

    hsla is an alias of hsl, and rgba of rgb. Both will automatically include the alpha component, if neccessary.

  ## Examples:

    ```
    iex> c = Colorex.parse!("#3355FF")
    iex> c = Colorex.format(c, :hsl)
    Colorex.parse!("hsl(230 100% 60%)")
    iex> to_string(c)
    "hsl(230 100% 60%)"
    ```
  """
  @spec format(
          colorex :: Colorex.Color.t(),
          format :: :hex | :hex24 | :hex32 | :hsl | :hsla | :rgb | :rgba
        ) :: Colorex.Color.t()
  def format(colorex, format) do
    %{colorex | format: Colorex.Format.get(format) || colorex.format}
  end

  @doc """
    Flattens any alpha value to 1.0 against the passed in color or white.

    Colors that contain an `alpha` value have some transparency to them, so their actual color would depend on what is behind them. This function converts a color with transparency, to a solid color based on the background color passed on, or the default of white

    You can also set the background color in your config with `:colorex, :background_color`

  ## Examples:

    ```
    iex> Colorex.flatten_alpha(Colorex.parse!("#3355FF7F"), Colorex.parse!("#FF5533"))
    Colorex.parse!("#995599")
    iex> Colorex.flatten_alpha(Colorex.parse!("#3355FF7F"), Colorex.parse!("#000000"))
    Colorex.parse!("#192A7F")
    iex> Colorex.flatten_alpha(Colorex.parse!("#3355FF7F"))
    Colorex.parse!("#99AAFF")
    iex> Application.put_env(:colorex, :background_color, "#00FF00")
    iex> Colorex.flatten_alpha(Colorex.parse!("#3355FF7F"))
    Colorex.parse!("#19AA7F")
    ```
  """
  @spec flatten_alpha(color :: color, background :: color | nil) :: color
  def flatten_alpha(color, bg \\ nil)

  def flatten_alpha(%Colorex.Color{color: color, background: bg} = c, bg2),
    do: %{c | color: flatten_alpha(color, bg2 || bg)}

  def flatten_alpha(col, nil), do: flatten_alpha(col, default_bg())

  def flatten_alpha(%{alpha: 1.0} = color, _), do: color

  def flatten_alpha(%{alpha: alpha} = color, bg),
    do: mix(%{color | alpha: 1.0}, flatten_alpha(bg), alpha)

  defp default_bg do
    Application.get_env(:colorex, :background_color, {255, 255, 255, 1.0}) |> parse!()
  rescue
    _ -> RGB.from_rgba({255, 255, 255, 1.0})
  end

  @doc """
    Sets the alpha channel to 100% without accounting for background color

  ## Examples:

    ```
    iex> Colorex.trunc_alpha(Colorex.parse!("#3355FF7F"))
    Colorex.parse!("#3355FF")
    ```

    If you want the color to be resolved taking into account a background color, use `flatten_alpha/1`/`flatten_alpha/2`
  """
  cdef(trunc_alpha(color), do: %{color | alpha: 1.0})
end
