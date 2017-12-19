defmodule MoneyWatcher.Mixfile do
  use Mix.Project

  def project do
    [
      app: :money_watcher,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MoneyWatcher, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 1.1.0"},
      {:plug, "~> 1.4.3"},
      {:bankster, "~> 0.2.2"}
    ]
  end
end
