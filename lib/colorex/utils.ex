defmodule Colorex.Utils do
  use Colorex.Types
  alias Colorex.RGB

  @doc """
    Generates a random color.
  """
  def random do
    Enum.map(1..3, fn _ -> :rand.uniform(256) - 1 end) |> List.to_tuple() |> Colorex.parse!()
  end

  @moduledoc """
  Some handy functions for working with colors
  """
  alias Colorex.ANSI

  @doc """
    Print a row of color swatches.

    Will print a colored square for each color in the list, all in a row.

    The `size` argument is the size of each square.

    Useful for debugging or seeing colors in the terminal. Requires a terminal that supports truecolor.
  """
  @spec print_swatches(list(color()), pos_integer()) :: :ok
  def print_swatches([_ | _] = list, size \\ 1) do
    Enum.map_join(list, " ", fn color ->
      ANSI.ansi_background(color) <> String.duplicate("  ", size) <> IO.ANSI.reset()
    end)
    |> Kernel.<>("\n")
    |> String.duplicate(size)
    |> IO.puts()
  end

  @doc """
    Print a visual of two colors being mixed.

    Prints two overlapping squares that look like colors being mixed.

    Arg 1 is the top right square. Arg 2 is the bottom left square. Arg 3 is the middle overlapping square. Arg 4 is an optional size parameter.

  <div>
  <pre>
          ┌──────────┐
          │   Arg 1  │
      ┌───│──────┐   │
      │   │ Arg3 │   │
      │   └──────────┘
      │  Arg 2   │
      └──────────┘

  </pre>
  </div>

    Requires a terminal that supports truecolor.
  """
  @spec print_color_mix(
          color :: color(),
          color2 :: color(),
          color3 :: color(),
          size :: pos_integer()
        ) :: :ok
  def print_color_mix(c1, c2, c3, size \\ 1) do
    top =
      String.duplicate("  ", size) <>
        ANSI.ansi_background(c1) <> String.duplicate("  ", size * 3) <> IO.ANSI.reset() <> "\n"

    mid =
      ANSI.ansi_background(c2) <>
        String.duplicate("  ", size) <>
        ANSI.ansi_background(c3) <>
        String.duplicate("  ", size * 2) <>
        ANSI.ansi_background(c1) <> String.duplicate("  ", size) <> IO.ANSI.reset() <> "\n"

    bottom =
      ANSI.ansi_background(c2) <>
        String.duplicate("  ", size * 3) <>
        IO.ANSI.reset() <> String.duplicate("  ", size) <> "\n"

    IO.puts(
      String.duplicate(top, size) <>
        String.duplicate(mid, size * 2) <>
        String.duplicate(bottom, size)
    )
  end

  @doc """
    Convienience function to get the color white
  """
  @spec white() :: Colorex.Color.t()
  def white, do: Colorex.Color.new(%RGB{red: 255, green: 255, blue: 255})

  @doc """
    Convienience function to get the color black
  """
  @spec black() :: Colorex.Color.t()
  def black, do: Colorex.Color.new(%RGB{red: 0, green: 0, blue: 0})
end
