defmodule Config do
  use Application

  def start(_type, _args) do
    Config.Supervisor.start_link()
  end

  def watch_config(internal_path, callback) do
    Config.Worker.watch_config(internal_path, callback)
  end
end


defmodule Config.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, nil)
  end

  def init(nil) do
    children = [
      supervisor(FileWatcher, []),
      worker(Config.Worker, [Application.get_env(:config, :config_paths)]),
    ]

    supervise(children, strategy: :rest_for_one)
  end
end


defmodule Config.Worker do
  use GenServer
  require Logger

  def start_link(config_paths) do
    GenServer.start_link(__MODULE__, config_paths, name: __MODULE__)
  end

  def watch_config(internal_path, callback) do
    GenServer.call(__MODULE__, {:add_listener, internal_path, callback})
  end


  def init(config_paths) do
    config_paths = Enum.map(config_paths, &Path.expand/1)
    config = merge_configs(config_paths)
    :ok = watch_files(config_paths)
    {:ok, %{config: config,
            config_paths: config_paths,
            listeners: [],
            watcher_ports: []}}
  end

  def handle_call({:add_listener, internal_path, callback}, _from, state) do
    state = Map.update!(state, :listeners, fn
       listeners -> listeners ++ [{internal_path, callback}]
    end)
    {:reply, get_in(state.config, internal_path), state}
  end

  def handle_cast({:reload, _path}, state) do
    case merge_configs(state.config_paths) do
      map when map == %{} -> {:noreply, state}
      new_config ->
        for {internal_path, callback} <- state.listeners do
          if get_in(state.config, internal_path) != get_in(new_config, internal_path) do
            callback.(get_in(new_config, internal_path))
          end
        end
        {:noreply, state |> Map.put(:config, new_config)}
    end
  end


  defp watch_files(files) do
    FileWatcher.watch_files(files, fn path -> GenServer.cast(__MODULE__, {:reload, path}) end)
    :ok
  end

  defp merge_configs(paths) do
    Enum.reduce(paths, %{}, fn
      path, all -> Map.merge(all, try_load_config(path))
    end)
  end

  defp try_load_config(path) do
    case File.read(Path.expand(path)) do
      {:ok, json} ->
        case Poison.decode(json) do
          {:ok, config} -> config
          {:error, reason} ->
            Logger.warn("File #{path} is not well-formed json, did not use it for config.\nError: #{inspect reason}")
            %{}
        end
      _ -> %{}
    end
  end
end
