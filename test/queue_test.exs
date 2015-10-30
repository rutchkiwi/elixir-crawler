defmodule QueueTest do
  use ExUnit.Case

  setup_all do
    Queue.start_link()
    :ok
  end

  test "empty" do
    assert Queue.dequeue == :empty
  	assert Queue.dequeue == :empty
  end

  test "simple" do
    Queue.enqueue(:a)
    assert Queue.dequeue == {:value, :a}
    assert Queue.dequeue == :empty
  end

  test "multiple" do
    Queue.enqueue(:a)
    Queue.enqueue(:b)
    assert Queue.dequeue == {:value, :a}
    assert Queue.dequeue == {:value, :b}
    assert Queue.dequeue == :empty
  end


end