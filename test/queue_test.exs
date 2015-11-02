defmodule QueueTest do
  use ExUnit.Case

  setup_all do
    Queue.start_link()
    :ok
  end

  test "empty" do
    refute_receive(_any, 50)
    assert Queue.size() == 0
  end

  test "simple" do
    Queue.enqueue(:a)
    assert Queue.size == 1

    assert Queue.dequeue == :a    
    refute_receive(_any, 50)
    assert Queue.size == 0
  end

  test "multiple" do
    Queue.enqueue(:a)
    Queue.enqueue(:b)
    Queue.enqueue(:c)
    assert Queue.size == 3

    assert Queue.dequeue == :a
    assert Queue.dequeue == :b
    assert Queue.dequeue == :c
    refute_receive(_any, 50)
    assert Queue.size == 0

  end
end