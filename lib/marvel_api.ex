defmodule Crossover.MarvelAPI do
	use GenServer

	@name API

	# Client functions

	def start_link(opts \\ []) do 
		GenServer.start_link(__MODULE__, :ok, [opts | [name: API]])
	end

	def add_hero(heroName) do
		GenServer.call(@name, {:add, heroName})
	end

	def get_hero(heroName) do
		GenServer.call(@name, {:get, heroName})
	end

	# server functions
	
	def init(args) do
		{:ok, args}
	end
	
	def handle_call({:add, heroName}, _from, state) do
		# @TODO get the hero from Marvel API, and add the top level + series.
		heroInfo = %{}
		new_state = update_state(heroInfo, state)
		{:reply, :ok, new_state}
	end

	def handle_call({:get, heroName}, _from, state) do
		case find_hero(state, heroName) do
			{:ok, hero} ->
				{:reply, hero, state}
			_ ->
				:error
		end
	end

	# helpers
	
	defp find_hero(heroName, state) do
		state |> Enum.find(fn(hero) -> hero["name"] == heroName end)
	end

	defp update_state(heroInfo, state) do
		[ heroInfo | state ]
	end
end