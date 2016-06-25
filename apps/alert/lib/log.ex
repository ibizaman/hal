defmodule Alert.Log do
  import Logger
  def alert(opts, tags, data) do
    level = opts |> Map.get("level", "info") |> String.to_atom
    message = "[" <> Enum.join(tags, ",") <> "] " <> data.message
    Logger.log(level, message)
  end
end
