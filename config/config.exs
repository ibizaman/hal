use Mix.Config

import_config "../apps/*/config/config.exs"

config :config,
  config_paths: ["/etc/hal/hal.conf", "~/.hal/hal.conf", "hal.conf"],
  filewatcher_exec: ["/usr/bin/fswatch", "/usr/local/bin/fswatch"],
  filewatcher_sharelib: "/usr/local/lib:/usr/lib"

