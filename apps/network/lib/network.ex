defmodule Network do
  use Application

  def start(_app, _args) do
    Network.Supervisor.start_link()
  end
end

defmodule Network.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, nil)
  end

  def init(nil) do
    children = [
      supervisor(Network.Services.Godaddy, []),
      supervisor(Network.Dyndns, []),
    ]

    supervise(children, strategy: :one_for_one)
  end
end
