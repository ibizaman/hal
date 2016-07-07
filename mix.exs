defmodule Hal.Mixfile do
  use Mix.Project

  def project do
    [apps_path: "apps",
     app: :hal,
     version: "0.0.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  defp deps do
    [
      {:exrm, "1.0.6"},
    ]
  end
end
