defmodule Alert do
  use Application

  def start(_type, _args) do
    Alert.Supervisor.start_link()
  end
end


defmodule Alert.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, nil)
  end

  def init(nil) do
    children = [
      Alert.Services.Mailgun.child_spec()
    ]

    supervise(children, strategy: :one_for_one)
  end
end

