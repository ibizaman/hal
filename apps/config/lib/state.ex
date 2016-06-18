defmodule Config.State do
  defmacro __using__(app: app, config_path: config_path) do
    quote do
      def start_link(nil) do
        Config.State.start_link(unquote(__CALLER__.module), unquote(app), unquote(config_path))
      end

      def child_spec(opts \\ []) do
        Config.State.child_spec(unquote(__CALLER__.module), opts)
      end

      defp _get(key) do
        Config.State.get(unquote(__CALLER__.module), key)
      end

      defp _find(fun) do
        Config.State.find(unquote(__CALLER__.module), fun)
      end
    end
  end

  def start_link(module, app, config_path) do
    case Config.watch_config(Application.get_env(app, config_path), &handle_config_change(module, &1)) do
      nil -> {:stop, "No configuration found for #{app}, #{config_path}"}
      config -> Agent.start_link(fn -> config end, name: module)
    end
  end

  def child_spec(module, opts \\ []) do
    Supervisor.Spec.worker(module, [nil | opts])
  end


  def get(module, key) when not is_list(key) do
    get(module, [key])
  end
  def get(module, key) do
    Agent.get(module, fn map -> get_in(map, key) end)
  end

  def find(module, fun) do
    Agent.get(module, &Enum.find(&1, fun))
  end

  defp handle_config_change(module, map) do
    Agent.update(module, fn _ -> map end)
  end
end
