defmodule Config.Mixfile do
  use Mix.Project

  def project do
    [app: :config,
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
    [applications: [:logger, :poison, :erlexec],
     mod: {Config, []}]
  end

  defp deps do
    [
      {:exrm, "1.0.6"},
      {:poison, "~> 2.0"},
      {:erlexec, github: "saleyn/erlexec", tag: "1.2.1"}
    ]
  end
end
