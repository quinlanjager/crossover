defmodule Crossover.MarvelAPITest do
  use ExUnit.Case
  doctest Crossover.MarvelAPI
  
  test "Adds an item to the state." do
  	state = Crossover.MarvelAPI.prepend_item_to_state("Pie", [])
  	assert state == ["Pie"]
  end

  test "Gets a character from marvelAPI." do
    assert {:ok, %HTTPoison.Response{}} = Crossover.MarvelAPI.get_character_from_api("thor") 
  end

  test "Gets a series from the marvelAPI." do
    ids = [1009664]
    assert {:ok, %HTTPoison.Response{}} = Crossover.MarvelAPI.get_series_with_characters_from_api(ids)
  end
end
