defmodule ImageProxy.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [
      app: :image_proxy,
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
      {:tesla, "~> 1.0"},
      {:telemetry, "~> 1.0"},
      {:jason, "~> 1.0"},
      {:telemetry_metrics, "~> 0.6"}
    ]
  end

  defp aliases do
    []
  end

  defp package do
    [
      maintainers: ["Simon Prévost"],
      licenses: ["BSD-3-Clause"],
      files: ~w(lib mix.exs README.md)
    ]
  end
end
