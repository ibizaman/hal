defmodule Alert do
  use Application
  import Logger

  def start(_type, _args) do
    Alert.Supervisor.start_link()
  end

  def alert(tags, data) do
    Logger.debug(inspect({tags, data}))
    Alert.Supervisor.alert(tags, data)
  end
end


defmodule Alert.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, nil)
  end

  def alert(tags, data) do
    :poolboy.transaction(:alert_pool,
      fn (pid) -> Alert.Pool.Worker.alert(pid, tags, data) end,
      :infinity
    )
  end


  def init(nil) do
    poolboy_config = [
      {:name, {:local, :alert_pool}},
      {:worker_module, Alert.Pool.Worker},
      {:size, 10},
      {:max_overflow, 5},
    ]

    children = [
      Alert.Services.Mailgun.child_spec(),
      Alert.Rules.child_spec(),
      :poolboy.child_spec(:alert_pool, poolboy_config, nil)
    ]

    supervise(children, strategy: :one_for_one)
  end
end


defmodule Alert.Rules do
  use Config.State, app: :alert, config_path: :rules_config_path

  def rules(tags) do
    case Enum.map(tags, &find/1) |> Enum.filter(fn rule -> rule != nil end) do
      [] -> [find("fallback")]
      rules -> rules
    end
  end

  defp find(target) when is_atom(target) do
    find(to_string(target))
  end
  defp find(target) do
    _find(fn %{"tag" => tag} -> tag == target end)
  end
end


defmodule Alert.Pool.Worker do
  use GenServer

  def start_link(nil) do
    GenServer.start_link(__MODULE__, nil)
  end

  def alert(pid, tag, data) when not is_list(tag) do
    alert(pid, [tag], data)
  end
  def alert(pid, tags, data) do
    GenServer.cast(pid, {:alert, tags, data})
  end


  def init(nil) do
    {:ok, %{stats: %{}}}
  end

  def handle_cast({:alert, tags, data}, state) do
    send_alert(tags, data)
    {:noreply, state}
  end


  defp send_alert(tags, data) do
    for rule <- Alert.Rules.rules(tags) do
      for service_opt <- Map.fetch!(rule, "services") do
        service = Application.get_env(:alert, :services)
                  |> Map.fetch!(Map.get(service_opt, "service"))
        service.alert(service_opt, tags, data)
      end
    end
  end
end

