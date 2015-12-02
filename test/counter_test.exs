defmodule CounterTest do
  use ExUnit.Case

  test "counting" do
    counter_pid = Counter.start_link()
    assert Counter.get(counter_pid) == 0
    Counter.increment(counter_pid) == 1
    Counter.increment(counter_pid) == 2
    assert Counter.get(counter_pid) == 2
    assert Counter.decrement(counter_pid) == 1
    assert Counter.get(counter_pid) == 1
    assert Counter.decrement(counter_pid) == 0
    assert Counter.get(counter_pid) == 0
  end

  test "increment by" do
    counter_pid = Counter.start_link()
    Counter.increment(counter_pid, 10) == 10
    assert Counter.get(counter_pid) == 10
  end
end