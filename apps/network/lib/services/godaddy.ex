defmodule Network.Services.Godaddy do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, nil)
  end

  def init(nil) do
    children = [
      Network.Services.Godaddy.Config.child_spec(),
      worker(Network.Services.Godaddy.Worker, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

  def update_ip(ip) do
    Network.Services.Godaddy.Worker.update_ip(ip)
  end
end


defmodule Network.Services.Godaddy.Config do
  use Config.State, app: :network, config_path: :godaddy_config_path

  def base_url() do
    "https://api.godaddy.com/v1"
  end

  def domain_url_suffix() do
    "/domains/#{_get("domain")}"
  end

  def domain_A_records_url_suffix(name \\ "") do
    "/domains/#{_get("domain")}/records/A/#{name}"
  end

  def base_headers() do
    %{"Accept" => "application/json", "Content-Type" => "application/json"}
  end

  def auth_header() do
     %{"Authorization" => "sso-key #{_get("key")}:#{_get("secret")}"}
  end
end


defmodule Network.Services.Godaddy.Worker do
  use GenServer
  alias Network.Services.Godaddy.Config

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def update_ip(ip) do
    ip = :inet.ntoa(ip) |> List.to_string
    {:ok, [current]} = get_domain_A_record("@")
    name = Map.get(current, "name")
    data = current |> Map.put("data", ip)
    {:ok, _} = put(Config.domain_A_records_url_suffix(name), [data])
    :ok
  end


  def handle_call({method, url_suffix, body}, _from, state) do
    case HTTPoison.request(
      method,
      Config.base_url <> url_suffix,
      body |> encode_body,
      Config.base_headers |> Map.merge(Config.auth_header)
    )
    do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:reply, {:ok, body |> decode_success_response}, state}
      {:ok, %HTTPoison.Response{status_code: _, body: reason}} ->
        {:reply, {:error, reason |> decode_error_response}, state}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:reply, {:error, reason}, state}
    end
  end


  defp get_domain_A_record(name) do
    get(Config.domain_A_records_url_suffix(name))
  end

  defp get(url_suffix) do
    GenServer.call(__MODULE__, {:get, url_suffix, ""})
  end

  defp put(url_suffix, body) do
    GenServer.call(__MODULE__, {:put, url_suffix, body})
  end

  defp encode_body(body) when is_binary(body) do
    body
  end
  defp encode_body(body) do
    body |> Poison.encode!
  end

  defp decode_success_response(r) do
    r |> Poison.decode!
  end

  defp decode_error_response(r) do
    r |> Poison.decode!
  end
end
