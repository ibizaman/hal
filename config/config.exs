use Mix.Config

import_config "../apps/*/config/config.exs"

config :hal,
  config_paths: ["/etc/hal/hal.conf", "~/.hal/hal.conf", "hal.conf"]
