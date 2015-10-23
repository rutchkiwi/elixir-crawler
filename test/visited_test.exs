defmodule VisitedTest do
  use ExUnit.Case

  test "empty" do
  	Visited.start_link()
  	assert not Visited.is_visited("a")
  end

  test "insert" do
  	Visited.start_link()

  	assert not Visited.is_visited("a")
  	Visited.mark_visited("a")
  	assert Visited.is_visited("a")
  end

  test "insert multiple" do
  	Visited.start_link()
  	
  	assert not Visited.is_visited("a")
  	Visited.mark_visited("a")
  	assert Visited.is_visited("a")

  	Visited.mark_visited("b")
  	Visited.mark_visited("c")

  	assert Visited.is_visited("a")
  	assert Visited.is_visited("b")
  	assert Visited.is_visited("c")
  end
end