defmodule Network.Dyndns do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, nil)
  end

  def init(nil) do
    children = [
      Network.Dyndns.Config.child_spec(),
      worker(Network.Dyndns.Worker, []),
    ]

    supervise(children, strategy: :one_for_one)
  end
end


defmodule Network.Dyndns.Config do
  use Config.State, app: :network, config_path: :dyndns_config_path

  def check_interval() do
    _get("check_interval")
  end

  def streak_error_alert() do
    _get("streak_error_alert")
  end
end


defmodule Network.Dyndns.Worker do
  use GenServer
  alias Network.Dyndns.Config

  defstruct [:ip, :last_message, :error_streak]

  def start_link() do
    GenServer.start_link(__MODULE__, nil, [])
  end

  def init(nil) do
    start_timer()
    {:ok, %__MODULE__{last_message: nil, error_streak: 0}}
  end

  def handle_info({:timer, :fetch_ip}, state) do
    start_timer()
    case Network.Services.Ipify.get_ip() do
      {:ok, ip} -> {:noreply, update_ip(state, ip)}
      {:error, message} -> {:noreply, update_error(state, message)}
    end
  end


  defp start_timer() do
    :timer.send_after(Config.check_interval, {:timer, :fetch_ip})
  end

  defp update_ip(state, ip) do
    case ip == state.ip do
      true -> state
      false ->
        alert_ip_change(state.ip, ip)
        Map.put(state, :ip, ip)
    end
  end

  defp update_error(state, message) do
    case {message, state.last_message} do
      {nil, old_message} ->
        alert_error_resolved(old_message, state.error_streak)
        state
        |> Map.put(:error_streak, 0)
        |> Map.put(:last_message, nil)
      {message, message} ->
        new_streak_count = state.error_streak + 1
        if rem(new_streak_count, Config.streak_error_alert) == 0 do
          alert_error_streak(message, new_streak_count)
        end
        Map.put(state, :error_streak, new_streak_count)
      {new_message, nil} ->
        alert_error_new(new_message)
        state
        |> Map.put(:error_streak, 0)
        |> Map.put(:last_message, new_message)
      {new_message, old_message} ->
        alert_error_changed(new_message, old_message, state.error_streak)
        state
        |> Map.put(:error_streak, 0)
        |> Map.put(:last_message, new_message)
    end
  end


  defp alert_ip_change(nil, new_ip) do
    Alert.alert([:network, :dyndns, :success, :change],
      %{new_ip: new_ip, old_ip: nil,
        summary: "New ip: #{new_ip}",
        message: "Starting with ip address #{new_ip}"})
  end
  defp alert_ip_change(old_ip, new_ip) do
    Alert.alert([:network, :dyndns, :success, :change],
      %{new_ip: new_ip, old_ip: old_ip,
        summary: "New ip: #{new_ip}",
        message: "Changed ip address from #{old_ip} to #{new_ip}"})
  end

  defp alert_error_new(message) do
    Alert.alert([:network, :dyndns, :error, :new_error],
      %{error: message, count: 1,
        summary: "Error new: #{message}",
        message: "Error new: #{message}"})
  end

  defp alert_error_resolved(old_message, streak) do
    Alert.alert([:network, :dyndns, :success, :error_resolved],
      %{error: old_message, count: streak,
        summary: "Error resolved: #{old_message}",
        message: "Error resolved after #{streak} tries: #{old_message}"})
  end

  defp alert_error_streak(message, streak) do
    Alert.alert([:network, :dyndns, :error, :cannot_resolve],
      %{error: message, count: streak,
        summary: "Error continue: #{message}",
        message: "Error is still happening after #{streak} tries: #{message}"})
  end

  defp alert_error_changed(new_message, old_message, streak) do
    Alert.alert([:network, :dyndns, :error, :cannot_resolve],
      %{error: new_message, count: 0,
        summary: "Error new: #{new_message}",
        message: "Error changed after #{streak} tries from #{old_message} to #{new_message}"})
  end
end
