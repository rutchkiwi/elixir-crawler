defmodule VisitedTest do
  use ExUnit.Case

  @a URI.parse("http://a.com")
  @b URI.parse("http://b.com")
  @c URI.parse("http://c.com")
  
  test "empty" do
    pid = Visited.start_link()
    assert not Visited.visited?(pid, "a")
    assert Visited.size(pid) == 0
  end

  test "insert" do
    pid = Visited.start_link()
    assert not Visited.visited?(pid, @a)
    Visited.mark_visited(pid, @a)
    assert Visited.visited?(pid, @a)
    assert Visited.size(pid) == 1
  end

  test "insert multiple" do
    pid = Visited.start_link()
    assert not Visited.visited?(pid, @a)
    Visited.mark_visited(pid, @a)
    assert Visited.visited?(pid, @a)

    Visited.mark_visited(pid, @b)
    Visited.mark_visited(pid, @c)

    assert Visited.visited?(pid, @a)
    assert Visited.visited?(pid, @b)
    assert Visited.visited?(pid, @c)
    assert Visited.size(pid) == 3
  end
end