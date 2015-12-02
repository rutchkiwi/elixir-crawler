defmodule QueueTest do
  use ExUnit.Case

  test "simple" do
    pid = Queue.start_link()
    Queue.enqueue(pid, :a)

    assert Queue.dequeue(pid) == :a    
    refute_receive(_any, 50)
  end

  test "multiple" do
    pid = Queue.start_link()

    Queue.enqueue(pid, :a)
    Queue.enqueue(pid, :b)
    Queue.enqueue(pid, :c)

    assert Queue.dequeue(pid) == :a
    assert Queue.dequeue(pid) == :b
    assert Queue.dequeue(pid) == :c
    refute_receive(_any, 50)

  end
end