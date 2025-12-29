defmodule AeX402.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/aldrin/ammasm"

  def project do
    [
      app: :aex402,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "AeX402",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  defp deps do
    [
      {:b58, "~> 1.0"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Elixir SDK for AeX402 Hybrid AMM on Solana.
    Supports stable pools (AeX402 curve) and volatile pools (constant product),
    N-token pools (2-8 tokens), farming, lottery, TWAP oracle, and more.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "AeX402",
      extras: ["README.md"]
    ]
  end
end
