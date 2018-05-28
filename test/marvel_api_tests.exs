defmodule Crossover.MarvelAPITest do
  use ExUnit.Case
  doctest Crossover.MarvelAPI
  
  test "Adds an item to the state." do
  	state = update_state("Pie", [])
  	assert state == ["Pie"]
  end

  test "Gets an item from state." do
  	item = find_hero([%{name: "Thor"}, "Thor"])
  	assert %{name: "Thor"} == item
  end
end
