defmodule Alert.Mixfile do
  use Mix.Project

  def project do
    [app: :alert,
     version: "0.0.1",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:httpoison, :poolboy],
     mod: {Alert, []}]
  end

  defp deps do
    [
      {:config, in_umbrella: true},
      {:poolboy, "~> 1.5"},
      {:poison, "~> 2.0"},
      {:httpoison, "~> 0.8.0"},
    ]
  end
end

