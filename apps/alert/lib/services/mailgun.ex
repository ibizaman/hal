defmodule Alert.Services.Mailgun do
  use Supervisor

  def start_link(nil) do
    Supervisor.start_link(__MODULE__, nil)
  end

  def init(nil) do
    poolboy_config = [
      {:name, {:local, :mailgun_pool}},
      {:worker_module, Alert.Services.Mailgun.Worker},
      {:size, 5},
      {:max_overflow, 2},
    ]

    children = [
      :poolboy.child_spec(:mailgun_pool, poolboy_config, {
        Application.get_env(:alert, "mailgun_domain"),
        Application.get_env(:alert, "mailgun_api_key")
      })
    ]

    options = [
      strategy: :one_for_one,
    ]

    supervise(children, options)
  end

  def send_email(email = %Alert.Email{}, test \\ false) do
    :poolboy.transaction(:mailgun_pool,
      fn (pid) -> Alert.Services.Mailgun.Worker.send_email(pid, email, test) end,
      :infinity
    )
  end

  def child_spec(opts \\ []) do
    worker(__MODULE__, [nil | opts])
  end
end


defmodule Alert.Services.Mailgun.Worker do
  use GenServer

  defstruct [:url, :auth]

  def start_link({domain, api_key}) do
    GenServer.start_link(__MODULE__, {domain, api_key}, [])
  end

  def send_email(pid, email = %Alert.Email{}, test \\ false) do
    GenServer.call(pid, {:send, email, test})
  end


  def init({domain, api_key}) do
    url = "https://api.mailgun.net/v3/" <> domain
    auth = [basic_auth: {"api", api_key}]
    {:ok, %__MODULE__{url: url, auth: auth}}
  end

  def handle_call({:send, email, test}, _from, state) do
    email = email |> Map.put(:test, (case test, do: (true -> "yes"; false -> "no")))
    case HTTPoison.post(
      state.url <> "/messages",
      {:form, encode_email(email)},
      %{"Content-type" => "application/x-www-form-urlencoded"},
      [hackney: state.auth])
    do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:reply, {:ok, body |> decode_success_response}, state}
      {:ok, %HTTPoison.Response{status_code: _, body: reason}} ->
        {:reply, {:error, reason |> decode_error_response}, state}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:reply, {:error, reason}, state}
    end
  end


  defp encode_email(email = %Alert.Email{}) do
    Map.from_struct(email)
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into([])
  end

  defp decode_success_response(response) do
    response
    |> Poison.decode!
  end

  defp decode_error_response(response) do
    case response |> Poison.decode do
      {:ok, %{"message" => decoded}} -> decoded
      _ -> response
    end
  end
end

