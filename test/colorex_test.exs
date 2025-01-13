defmodule ColorexTest do
  use ExUnit.Case

  test "parse!" do
    assert %Colorex.Color{} = p!("#FF0000")
    assert %Colorex.Color{} = p!("#FF0000FF")
    assert %Colorex.Color{} = p!("red")
    assert %Colorex.Color{} = p!("rgb(255 0 0)")
    assert %Colorex.Color{} = p!("rgb(255, 0, 0)")
    assert %Colorex.Color{} = p!("rgba(255, 0, 0)")
    assert %Colorex.Color{} = p!("rgba(255 0 0)")
    assert %Colorex.Color{} = p!("rgba(255 0 0 100%)")
    assert %Colorex.Color{} = p!("rgba(255 0 0 1.0)")
    assert %Colorex.Color{} = p!("hsl(0 100% 50%)")
    assert %Colorex.Color{} = p!("hsl(0 100% 50% 100%)")
  end

  test "text_color/2" do
    assert %Colorex.Color{color: %{red: 255, green: 255, blue: 255}} =
             Colorex.text_color(black())

    assert "black" = Colorex.text_color(white(), white: "white", black: "black")
  end

  defp white, do: Colorex.Utils.white()
  defp black, do: Colorex.Utils.black()

  test "average/1" do
    colors = [rgb(255, 0, 0), rgb(0, 255, 0), rgb(0, 0, 255)]
    assert {147, 147, 147, 1.0} == Colorex.average(colors) |> Colorex.rgba_tuple()
    colors = [p!("#FF0000"), p!("#00FF00"), p!("#0000FF")]
    assert {147, 147, 147, 1.0} == Colorex.average(colors) |> Colorex.rgba_tuple()
  end

  test "similarity" do
    assert Colorex.similarity(black(), white()) < 0.25
    assert Colorex.fast_similarity(black(), white()) < 0.25
    assert Colorex.distance(black(), white()) > 0.75
    assert Colorex.fast_distance(black(), white()) > 0.75
    assert Colorex.similarity(black(), black()) > 0.75
    assert Colorex.fast_similarity(black(), black()) > 0.75
    assert Colorex.distance(black(), black()) < 0.25
    assert Colorex.fast_distance(black(), black()) < 0.25
  end

  test "random" do
    assert %Colorex.Color{} = Colorex.Utils.random()
    assert Colorex.Utils.random() != Colorex.Utils.random()
  end

  test "most_similar/2" do
    assert "#505050" ==
             Colorex.most_similar(p!("#454545"), [p!("#454565"), p!("#654545"), p!("#505050")])
             |> to_string()

    assert "#505050" ==
             Colorex.most_similar(p!("#454545"), [p!("#454565"), p!("#654545"), p!("#505050")],
               fast: false
             )
             |> to_string()
  end

  test "update/3" do
    assert "#000000" ==
             Colorex.update(p!("#556677"), :lightness, fn _, {min, _} -> min end) |> to_string()

    assert "#000000" == Colorex.update(p!("#556677"), :lightness, fn _ -> 0.0 end) |> to_string()

    assert "#FF6677" ==
             Colorex.update(p!("#556677"), :red, fn _, {_, max} -> max end) |> to_string()

    assert "#FF6677" == Colorex.update(p!("#556677"), :red, fn _ -> 255 end) |> to_string()

    assert "#550077" ==
             Colorex.update(p!("#556677"), :magenta, fn _, {_, max} -> max end) |> to_string()

    assert "#550077" == Colorex.update(p!("#556677"), :magenta, fn _ -> 1.0 end) |> to_string()

    [
      :l,
      :a,
      :b,
      :red,
      :green,
      :blue,
      :alpha,
      :cyan,
      :magenta,
      :yellow,
      :black,
      :x,
      :y,
      :z,
      :hue,
      :saturation,
      :lightness
    ]
    |> Enum.each(fn key ->
      assert %Colorex.Color{} = Colorex.update(p!("#445566"), key, fn val -> val * 1.1 end)

      assert %Colorex.Color{} =
               Colorex.update(p!("#445566"), key, fn _, {min, max} -> (max - min) / 2 end)
    end)
  end

  test "darkmode/1" do
    c = p!("#FF0000")
    assert Colorex.get(c, :saturation) > c |> Colorex.darkmode() |> Colorex.get(:saturation)
  end

  test "shade_number/1" do
    assert Colorex.shade_number(p!("#FF0000")) > Colorex.shade_number(p!("#552233"))
  end

  test "lighten/2" do
    assert Colorex.shade_number(Colorex.lighten(p!("#FF0000"), 0.5)) >
             Colorex.shade_number(p!("#FF0000"))
  end

  test "darken/2" do
    assert Colorex.shade_number(Colorex.darken(p!("#FF0000"), 0.5)) <
             Colorex.shade_number(p!("#FF0000"))
  end

  test "grayscale/1" do
    assert Colorex.grayscale?(Colorex.grayscale(p!("#FF0000")))
  end

  test "mix/3" do
    assert "#404040" == Colorex.mix(p!("#FF00FF"), p!("#005500"), 0.25) |> to_string()
  end

  test "spectral_mix/3" do
    assert "#388F54" == Colorex.spectral_mix(p!("#0000FF"), p!("#FFFF00")) |> to_string()
  end

  test "get/2" do
    assert Colorex.get(p!("#FF0000"), :saturation) == 1.0
    assert Colorex.get(p!("#FF0000"), :red) == 255
    assert Colorex.get(p!("#FF00007F"), :alpha) |> Float.round(1) == 0.5
  end

  test "put/3" do
    assert Colorex.put(p!("#000000"), :lightness, 1.0) |> to_string() == "#FFFFFF"
    assert Colorex.put(p!("#000000"), :red, 255) |> to_string() == "#FF0000"
  end

  test "format/2" do
    assert "hsl" <> _ = Colorex.format(p!("#FF0000"), :hsl) |> to_string()
  end

  test "flatten_alpha/2" do
    assert "#FFFFFF" == Colorex.flatten_alpha(p!("#FF000000")) |> to_string()
    assert "#FF0000" == Colorex.flatten_alpha(p!("#FF000000"), p!("#FF0000")) |> to_string()
  end

  test "String.Chars" do
    Enum.each([:rgb, :hsl, :cmyk, :xyz, :lab], fn space ->
      assert "" <> _ = p!("red") |> Colorex.to_colorspace(space) |> to_string()
    end)
  end

  defp p!(val), do: Colorex.parse!(val)

  defp rgb(r, g, b, a \\ 1.0), do: %Colorex.RGB{red: r, green: g, blue: b, alpha: a}
end
