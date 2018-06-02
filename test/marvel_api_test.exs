defmodule Crossover.MarvelAPITest do
  use ExUnit.Case
  doctest Crossover.MarvelAPI

  test "Gets a character from marvelAPI." do
    assert {:ok, %HTTPoison.Response{}} = Crossover.MarvelAPI.get_character_from_api("thor")
  end

  test "Gets a series from the marvelAPI." do
    ids = [1009664]

    assert {:ok, %HTTPoison.Response{}} = Crossover.MarvelAPI.get_series_with_characters_from_api(ids)
  end 

  test "Gets a list of series names containing characters" do
    assert [] = Crossover.MarvelAPI.get_series_with(["thor", "wolverine"])
  end
end
