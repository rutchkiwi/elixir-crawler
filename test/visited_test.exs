defmodule VisitedTest do
  use ExUnit.Case

  @a URI.parse("http://a.com")
  @b URI.parse("http://b.com")
  @c URI.parse("http://c.com")

  test "empty" do
  	Visited.start_link()
  	assert not visited?("a")
  end

  def visited?(uri) do
    visited = Visited.get_visited()
    Set.member?(visited, uri)
  end

  test "insert" do
  	Visited.start_link()

  	assert not visited?(@a)
  	Visited.mark_visited(@a)
  	assert visited?(@a)
  end

  test "insert multiple" do
  	Visited.start_link()
  	
  	assert not visited?(@a)
  	Visited.mark_visited(@a)
  	assert visited?(@a)

  	Visited.mark_visited(@b)
  	Visited.mark_visited(@c)

  	assert visited?(@a)
  	assert visited?(@b)
  	assert visited?(@c)
  end
end