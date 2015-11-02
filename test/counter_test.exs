defmodule CounterTest do
  use ExUnit.Case

  test "counting" do
    counter_pid = Counter.start_link()
    Process.register(counter_pid, :test_counter)

    assert Counter.get(:test_counter) == 0
    Counter.increment(:test_counter) == 1
    Counter.increment(:test_counter) == 2
    assert Counter.get(:test_counter) == 2
    assert Counter.decrement(:test_counter) == 1
    assert Counter.get(:test_counter) == 1
    assert Counter.decrement(:test_counter) == 0
    assert Counter.get(:test_counter) == 0

  end
end