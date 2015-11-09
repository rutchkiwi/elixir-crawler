defmodule QueueTest do
  use ExUnit.Case

  setup_all do
    Queue.start_link()
    :ok
  end

  test "simple" do
    Queue.enqueue(:a)

    assert Queue.dequeue == :a    
    refute_receive(_any, 50)
  end

  test "multiple" do
    Queue.enqueue(:a)
    Queue.enqueue(:b)
    Queue.enqueue(:c)

    assert Queue.dequeue == :a
    assert Queue.dequeue == :b
    assert Queue.dequeue == :c
    refute_receive(_any, 50)

  end
end