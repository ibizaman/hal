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
    result =
      with {:ok, exec_path} <- exec,
           {:ok, paths} <- watch(exec_path, Application.get_env(:config, :filewatcher_sharelib), paths),
        do: {:ok, paths}

    case result do
      {:ok, paths} -> {:ok, %{paths: paths, callback: callback}}
      {:error, reason} -> {:stop, "Could not watch files #{inspect paths}: #{inspect reason}"}
    end
  end


  def handle_info({:stdout, _pid, data}, state) do
    for line <- String.split(data, "\n") do
      call_callback(line, state)
    end
    {:noreply, state}
  end

  def handle_info({:stderr, _pid, data}, state) do
    Logger.warn("Got warning or error while watching file: #{inspect data}")
    {:noreply, state}
  end


  def call_callback("", _state) do
  end
  def call_callback(data, state) do
    [path, flags] = String.split(data, << 0 >>)
    flags = flags |> String.split(",")

    if Enum.member?(flags, "Updated") do
      state.callback.(path)
    end
  end


  defp watch(exec_path, shared_lib_paths, paths) do
    args = [exec_path,
            "--format=%p%0%f",
            "--event-flag-separator=,"
            | paths]
          |> Enum.join(" ")
          |> String.to_char_list
    options = [:stdout,
               :stderr,
               env: [{'LD_LIBRARY_PATH', shared_lib_paths |> String.to_char_list}]]

    case :exec.run_link(args, options) do
      {:ok, _pid, _ospid} -> {:ok, paths}
      {:error, reason} -> {:stop, "Could not watch files #{inspect paths}: #{inspect reason}"}
    end
  end

  defp exec() do
    paths = Application.get_env(:config, :filewatcher_exec)
    case paths |> Enum.filter(&File.regular?/1) do
      [] -> {:error, "No file found in #{inspect paths}"}
      [path | _] -> {:ok, path}
    end
  end
end
