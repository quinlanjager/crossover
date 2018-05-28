defmodule Crossover.MarvelAPI do
	use GenServer
	use HTTPoison.Base

	@endpoint "http://gateway.marvel.com"

	# Client functions

	def start_link(opts \\ []) do 
		GenServer.start_link(__MODULE__, :ok, opts)
	end

	def add_char(pid, char_name) do
		GenServer.call(pid, {:add, char_name})
	end

	def get_char(pid, char_name) do
		GenServer.call(pid, {:get, char_name}, 1000000)
	end

	# server functions
	
	def init(args) do
		{:ok, args}
	end

	def process_url(url) do
		@endpoint <> url
	end
	
	def handle_call({:add, char_name}, _from, state) do
		# @TODO get the char from Marvel API, and add the top level + series.
		case find_char(char_name) do
			{:ok, char_info} ->
				new_state = update_state(state, char_info)
				{:reply, char_info, new_state}
			{:error, reason} ->
				{:reply, reason, state}
		end
	end

	def handle_call({:get, char_name}, _from, state) do
		state |> Enum.find(fn(char) -> char[:name] == char_name end)
	end

	defp find_char(char_name) do
		IO.puts @endpoint <> "/v1/public/characters?name=#{char_name}&" <> make_auth_signature()
		case get("/v1/public/characters?name=#{char_name}&" <> make_auth_signature()) do
			{:ok, %HTTPoison.Response{body: char_info}} -> 
				decode_char_info(char_info)
			{:error, reason} ->
				{:error, reason}
		end	
	end

	defp decode_char_info(char_info) do
		try do
			{:ok, JSON.decode(char_info)}
		rescue
			_ ->
				{:error, "Couldn't decode JSON."}
		end
	end

	defp update_state(state, char_info) do
		[ char_info | state ]
	end

	defp make_auth_signature do
		time_stamp = DateTime.utc_now() |> DateTime.to_time |> to_string
		api_key = Application.fetch_env!(:crossover, :api_key)
		secret_key = Application.fetch_env!(:crossover, :secret_key)
		hash = :crypto.hash(:md5, time_stamp <> secret_key <> api_key) |> Base.encode16(case: :lower)
		"ts=#{URI.encode(time_stamp)}&apikey=#{api_key}&hash=#{hash}"
	end
end