defmodule Timedot.MixProject do
  use Mix.Project

  @version "0.1.0"
  @url "https://github.com/justndv/timedot"

  def project do
    [
      app: :timedot,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "Timedot",
      source_url: @url
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_parsec, "~> 1.0"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.4", only: [:dev]},
      {:ex_doc, "~> 0.24", only: [:dev], runtime: false}
    ]
  end

  defp description() do
    "Library for working with hledger's timedot format."
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      licenses: ["MIT"],
      links: %{"GitHub" => @url}
    ]
  end
end
