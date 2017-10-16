defmodule DownloadPerformanceTest.Mixfile do
  use Mix.Project

  def project do
    [
      app: :download_performance_test,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets, :hackney, :ibrowse]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hackney, "~> 1.9"},
      {:ibrowse, "~> 4.4"},
    ]
  end
end
