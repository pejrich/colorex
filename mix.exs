defmodule Colorex.MixProject do
  use Mix.Project

  def project do
    [
      app: :colorex,
      version: "1.0.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      name: "Colorex",
      source_url: "https://github.com/pejrich/colorex",
      docs: &docs/0,
      aliases: aliases()
    ]
  end

  def docs do
    [
      # The main page in the docs
      main: "Colorex",
      extras: ["README.md", "NamedColors.md"],
      before_closing_body_tag: &before_closing_body_tag/1
    ]
  end

  def description, do: "A library for working with colors. Mixing, comparing, adjusting and more."

  def package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/pejrich/shimmy"}
    ]
  end

  def before_closing_body_tag(_) do
    """
    <script>
    window.onload = function() {
    console.log("load called");
    Array.from(document.querySelectorAll("code.makeup span")).forEach((elem) => {
    elem.innerHTML = elem.innerHTML.replace(/rgba?[(].*?[)]/g, (i,j,k) => {
      return `<span style='background-color: ${i};'>${i}</span>`;
    })

    elem.innerHTML = elem.innerHTML.replace(/hsla?[(].*?[)]/g, (i,j,k) => {
      return `<span style='background-color: ${i};'>${i}</span>`;
    })
    elem.innerHTML = elem.innerHTML.replace(/\#[A-Fa-f0-9]{3,8}/g, (i) => `<span style='background-color: ${i};'>${i}</span>`);
    })
    }
    </script>
    """
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: extra_applications(Mix.env())
    ]
  end

  defp extra_applications(:dev),
    do: [:wx, :syntax_tools, :logger, :runtime_tools, :tools, :observer]

  defp extra_applications(_), do: [:logger]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, ">= 0.0.0"},
      {:benchee, ">= 0.0.0", only: [:dev]},
      {:ex_doc, ">= 0.0.0", only: [:dev], runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  def aliases do
    [docs: ["compile", &generate_named_colors/1, "docs", &copy_images/1]]
  end

  defp copy_images(_) do
    File.mkdir_p!("doc/images") |> IO.inspect()

    Path.wildcard("images/*")
    |> Enum.each(&File.cp!(&1, "doc/images/#{Path.basename(&1)}"))
  end

  defp generate_named_colors(_) do
    Code.ensure_loaded?(Colorex)
    colors = Colorex.Support.parse_tsv("priv/named_colors.tsv")

    body =
      colors
      |> Enum.sort_by(fn [a | _] -> String.downcase(a) end)
      |> Enum.map(fn [name, key, hex, source] ->
        {Colorex.parse!(hex),
         "<tr><td>#{name}</td><td><code>#{key}</code></td><td><code>#{hex}</code></td><td>#{source}</td><td style='background: #{hex};'></td></tr>"}
      end)

    az = Enum.map_join(body, &elem(&1, 1))

    light_dark =
      body
      # |> tap(fn x -> Enum.take(x, 10) |> IO.inspect() end)
      |> Enum.sort_by(fn {color, _} -> Colorex.shade_number(color) end)
      # |> tap(fn x -> Enum.take(x, 10) |> IO.inspect() end)
      |> Enum.map_join(&elem(&1, 1))

    hue =
      body
      |> Enum.split_with(fn {color, _} -> Colorex.grayscale?(color, 3) end)
      |> then(fn {gray, colors} ->
        Enum.sort_by(colors, fn {color, _} ->
          {round(Colorex.get(color, :hue) / 6) * 6, Colorex.shade_number(color)}
        end)
        |> Enum.concat(Enum.sort_by(gray, &Colorex.shade_number(elem(&1, 0))))
      end)
      |> Enum.map_join(&elem(&1, 1))

    md = """
    # Named Colors

    ### Below is a list of all #{length(colors)} named colors.

    When using named colors with `Colorex.parse/1` or `Colorex.parse!/1` the text from the `Keyword` column is the value you want to use. It is always lowercase a-z letters.

    <!-- tabs-open -->

    ### A-Z

    #{wrap_table(az)}

    ### Hue

    #{wrap_table(hue)}

    ### Dark - Light

    #{wrap_table(light_dark)}

    <!-- tabs-close -->

    """

    File.write!("NamedColors.md", md)
  end

  defp wrap_table(body) do
    """
    <div>
      <table>
        <thead>
          <tr>
            <th scope="col">Name</th>
            <th scope="col">Keyword</th>
            <th scope="col">RGB hex value</th>
            <th scope="col">Source</th>
            <th scope="col">Sample</th>
          </tr>
        </thead>
        <tbody>
          #{body}
        </tbody>
      </table>
    </div>
    """
  end
end
