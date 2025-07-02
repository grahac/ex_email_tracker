defmodule ExEmailTracker.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_email_tracker,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Email tracking for Phoenix/Swoosh applications",
      package: package(),
      docs: docs(),
      source_url: "https://github.com/yourusername/ex_email_tracker"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 0.20"},
      {:ecto_sql, "~> 3.10"},
      {:swoosh, "~> 1.14"},
      {:plug, "~> 1.14"},
      {:jason, "~> 1.4"},
      {:nimble_csv, "~> 1.2"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:postgrex, ">= 0.0.0", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/yourusername/ex_email_tracker"},
      maintainers: ["Your Name"]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end