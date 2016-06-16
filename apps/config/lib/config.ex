defmodule Config do
  @spec load_config(atom, Path | [Path]) :: {:ok, Map} | {:error, String}
  def load_config(app, paths) when is_list(paths) do
    return_first(paths, &load_config(app, &1))
  end

  def load_config(app, path) do
    case File.read(Path.expand(path)) do
      {:ok, json} ->
        case Poison.decode(json) do
          {:ok, config} ->
            Enum.map(config, fn {key, value} ->
              Application.put_env(app, key, value)
            end)
            {:ok, config}
          error -> error
        end
      error -> error
    end
  end


  defp return_first(list, fun, last_error \\ nil)

  defp return_first([], _fun, last_error) do
    last_error
  end

  defp return_first([arg | rest], fun, _last_error) do
    case fun.(arg) do
      {:ok, result} -> {:ok, result}
      error -> return_first(rest, fun, error)
    end
  end
end
