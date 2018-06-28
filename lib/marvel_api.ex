defmodule Crossover.MarvelAPI do
  use GenServer
  use HTTPoison.Base

  @endpoint "http://gateway.marvel.com"
  @timeout 20000

  # Interface functions
  # @TODO use multiple processes to asynchronously get character information
  def get_series_with(character_names) do
    {:ok, pid} = start_genserver()

    character_ids = character_names |> Enum.map(fn(character) -> get_character_id(pid, character) end) 
    IO.puts get_series_names(pid, character_ids) |> Enum.join("\n")
    GenServer.stop(pid)
    :ok
  end

  # Client functions
  defp start_genserver(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_character_id(pid, character_name) do
    encoded_character_name = URI.encode(character_name)
    endpoint = "/v1/public/characters?name=#{encoded_character_name}&" <> make_auth_signature()
    response_from_marvel = GenServer.call(pid, {:get, endpoint})

    case response_from_marvel do
      {:ok, %HTTPoison.Response{body: response_body}} ->
        response_body |> fetch_character_id_from_body
      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_series_names(pid, character_ids) do
    joined_list = character_ids |> Enum.join(",")
    endpoint = "/v1/public/series?characters=#{joined_list}&" <> make_auth_signature()
    
    response_from_marvel = GenServer.call(pid, {:get, endpoint }, @timeout)

    case response_from_marvel do
      {:ok, %HTTPoison.Response{body: response_body}} ->
        response_body |> map_series_names
      {:error, reason} ->
        {:error, reason}
    end
  end

  # GenServer callbacks
  def init(args) do
    {:ok, args}
  end

  def handle_call({:get, endpoint}, _from, state) do
    response = get(endpoint, [], [recv_timeout: @timeout])
    {:reply, response, state}
  end

  # HTTPoison callbacks
  def process_url(url) do
    @endpoint <> url
  end

  # helper functions
  
  defp fetch_character_id_from_body(response_from_marvel) do
    {:ok, character_info} = JSON.decode(response_from_marvel)
    case character_info["data"]["results"] |> Enum.fetch(0) do
      {:ok, first_character_result} ->
        first_character_result["id"]
      :error ->
        ""
    end
  end

  defp map_series_names(response_from_marvel) do
    {:ok, series_info} = JSON.decode(response_from_marvel) 
    series_info["data"]["results"] |> Enum.map(fn(series) -> series["title"] end)
  end

  defp make_auth_signature do
    time_stamp = DateTime.utc_now() |> DateTime.to_time() |> to_string
    api_key = Application.fetch_env!(:crossover, :api_key)
    secret_key = Application.fetch_env!(:crossover, :secret_key)
    hash = :crypto.hash(:md5, time_stamp <> secret_key <> api_key) |> Base.encode16(case: :lower)
    
    "ts=#{URI.encode(time_stamp)}&apikey=#{api_key}&hash=#{hash}"
  end
end
