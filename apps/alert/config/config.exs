use Mix.Config

config :alert,
  rules_config_path: ["alert", "rules"],
  mailgun_config_path: ["alert", "mailgun"],
  services: %{
    "email" => Alert.Email,
    "log" => Alert.Log,
    "mailgun" => Alert.Services.Mailgun}
