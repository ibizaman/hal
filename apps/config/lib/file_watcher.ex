defmodule FileWatcher do
  use GenServer

  def start_link() do
    FileWatcher.Supervisor.start_link()
  end

  def watch_files(paths, callback) do
    Supervisor.start_child(FileWatcher.Supervisor, [paths, callback])
  end
end

defmodule FileWatcher.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(nil) do
    children = [
      worker(FileWatcher.Watcher, []),
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end

defmodule FileWatcher.Watcher do
  use GenServer
  import Logger

  def start_link(paths, callback) do
    GenServer.start_link(__MODULE__, {paths, callback})
  end

  def init({path, callback}) when not is_list(path) do
    init({[path], callback})
  end

  def init({paths, callback}) do
    exec = {:spawn_executable, Application.get_env(:config, :filewatcher_exec)}
    args = ["--format=%p%0%f", "--event-flag-separator=," | paths]
    options = [
      {:args, args},
      {:line, 1000},
      {:env, [{'LD_LIBRARY_PATH', Application.get_env(:config, :filewatcher_sharelib) |> String.to_char_list}]},
      :use_stdio]

    case Port.open(exec, options) do
      nil -> {:stop, "Could not open port to watch files #{inspect paths}"}
      port -> {:ok, %{paths: paths, callback: callback, port: port}}
    end
  end

  def handle_info({'EXIT', _port, posix_code}, state) do
    Logger.error("Port closed with error code #{inspect posix_code}")
    {:stop, :port_already_closed, state}
  end

  def handle_info({_port, {:data, {:eol, data}}}, state) do
    [path, flags] = String.split(List.to_string(data), << 0 >>)
    flags = flags |> String.split(",")
    if Enum.member?(flags, "Updated") do
      state.callback.(path)
    end
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warn("Unhandled message #{inspect msg}")
    {:noreply, state}
  end

  def terminate(:port_already_closed, _state) do
    :ok
  end
  def terminate(_reason, state) do
    Port.close(state.port)
    :ok
  end
end
