defmodule Crossover.MarvelAPI do
  use GenServer
  use HTTPoison.Base

  @endpoint "http://gateway.marvel.com"

  # Interface functions
  def get_series_with(characters) do
    {:ok, pid} = start_genserver()
    # loop over each character name, put their ids in the state
    character_ids = characters 
    	|> Enum.map(fn(character) -> get_character_id(pid, character) end) 
    	|> Enum.join(",")
    
  end

  # Client functions
  defp start_genserver(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_character_id(pid, character_name) do
    GenServer.call(pid, {:get, character_name})
  end

  # GenServer callbacks
  def init(args) do
    {:ok, args}
  end

  def handle_call({:get, character_name}, _from, state) do
    response_from_marvel = get_character_from_api(character_name)

    case response_from_marvel do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_from_marvel}} ->
        character_id = response_from_marvel |> filter_character_id
        new_state = [character_id | state]
        {:reply, character_id, new_state}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # HTTPoison callbacks
  def process_url(url) do
    @endpoint <> url
  end

  # API functions
  def get_character_from_api(character_name) do
    get("/v1/public/characters?name=#{character_name}&" <> make_auth_signature())
  end

  def get_series_with_characters_from_api(character_ids) do
    joined_list = character_ids |> Enum.join(",")
    get("/v1/public/series?characters=#{joined_list}&" <> make_auth_signature())
  end

  # helper functions
  
  defp filter_character_id(response_from_marvel) do
    {:ok, character_info} = JSON.decode(response_from_marvel)
   	{:ok, first_character_result} = character_info["data"]["results"] |> Enum.fetch(0)
   	first_character_result["id"]
  end

  defp make_auth_signature do
    time_stamp = DateTime.utc_now() |> DateTime.to_time() |> to_string
    api_key = Application.fetch_env!(:crossover, :api_key)
    secret_key = Application.fetch_env!(:crossover, :secret_key)
    hash = :crypto.hash(:md5, time_stamp <> secret_key <> api_key) |> Base.encode16(case: :lower)

    "ts=#{URI.encode(time_stamp)}&apikey=#{api_key}&hash=#{hash}"
  end
end
