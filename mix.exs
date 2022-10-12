defmodule PlugImageProcessing.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [
      app: :plug_image_processing,
      version: @version,
      elixir: "~> 1.13",
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      xref: [exclude: IEx],
      deps: deps()
    ]
  end

  def application do
    [mod: []]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:plug, "~> 1.0"},
      {:vix, "~> 0.13"},
      {:finch, "~> 0.13"},
      {:telemetry, "~> 1.0"},
      {:jason, "~> 1.0"},
      {:telemetry_metrics, "~> 0.6"},

      # Linting
      {:credo, "~> 1.1", only: [:dev, :test]},
      {:credo_envvar, "~> 0.1", only: [:dev, :test], runtime: false},
      {:credo_naming, "~> 2.0", only: [:dev, :test], runtime: false},

      # Docs
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    []
  end

  defp package do
    [
      maintainers: ["Simon Prévost"],
      licenses: ["BSD-3-Clause"],
      links: %{github: "https://github.com/mirego/plug_image_processing"},
      files: ~w(lib mix.exs README.md)
    ]
  end
end
