# Colorex

An Elixir library for working with colors. Mixing, adjusting, converting(RGB, HSL, XYZ, LAB, CMYK), distance, and more.

## Installation

The package can be installed by adding `colorex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:colorex, "~> 1.0.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/colorex](https://hexdocs.pm/colorex).


## Why Colorex?

### Implements Inspect Protocol 

Colors are a visual thing. Stop copy/pasting hex codes between your terminal and another app just to see what the colors look like. If you have a terminal that supports truecolor/24-bit color, then Colorex will show you exactly what the color looks like, right in the terminal.

### More Colorspaces

If you want a lighter color, doing it in the HSL colorspace makes the most sense. If you want the distance between two colors, then using the LAB/CIELAB colorspace is the most accurate. Or if you don't really care about colorspaces and just want it to work, then Colorex can abstract all that stuff away. 

### Spectral Color Mixing

I remember the first time I mixed yellow and blue together on a computer. As I sat there staring at the result, I couldn't figure out what was more gross, the ugly gray color in front of me(rather than the expected green), or the fact that my elementary school teacher had lied to me. But the good news is, it turns out she only _half_ lied to me, because most of the time yellow and blue **do** make green, but on the computer they usually don't. But Colorex implements a spectral mixing function that will give color mixing more like real life paint/pigment color mixing.

### Color Palettes

Colorex has thousands of color palettes you can choose from, or if you prefer to make your own, Colorex has the tools to help.

## Acknowledgements

This was originally a fork of the elixir [css_colors](https://github.com/alvinlindstam/css_colors) library. Though it has diverged quite a bit, I thank them for laying out the foundations.

## License

MIT
