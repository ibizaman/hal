defmodule Network.Services.Ipify do
  def url do
    'https://api.ipify.org?format=json'
  end

  def get_ip() do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body |> decode_success_response}
      {:ok, %HTTPoison.Response{status_code: _, body: reason}} ->
        {:error, "Could not get external address ip: #{reason}"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Could not get external address ip: #{reason}"}
    end
  end

  defp decode_success_response(response) do
    response
    |> Poison.decode!
    |> Map.get("ip")
    |> :inet.parse_ipv4strict_address
  end
end
