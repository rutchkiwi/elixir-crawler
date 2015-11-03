defmodule VisitedTest do
  use ExUnit.Case

  @a URI.parse("http://a.com")
  @b URI.parse("http://b.com")
  @c URI.parse("http://c.com")
  
  setup do
  	Visited.start_link()
    :ok
  end

  test "empty" do
  	assert not Visited.visited?("a")
    assert Visited.size() == 0
  end

  test "insert" do
    assert not Visited.visited?(@a)
    Visited.mark_visited(@a)
    assert Visited.visited?(@a)
    assert Visited.size() == 1
  end

  test "insert multiple" do
    assert not Visited.visited?(@a)
    Visited.mark_visited(@a)
    assert Visited.visited?(@a)

    Visited.mark_visited(@b)
    Visited.mark_visited(@c)

    assert Visited.visited?(@a)
    assert Visited.visited?(@b)
    assert Visited.visited?(@c)
    assert Visited.size() == 3
  end
end