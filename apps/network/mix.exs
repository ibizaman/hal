defmodule Network.Mixfile do
  use Mix.Project

  def project do
    [app: :network,
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
    [applications: [:config, :alert, :httpoison],
     mod: {Network, []}]
  end

  defp deps do
    [
      {:alert, in_umbrella: true},
      {:config, in_umbrella: true},
      {:poison, "~> 2.0"},
      {:httpoison, "~> 0.8.0"},
    ]
  end
end

