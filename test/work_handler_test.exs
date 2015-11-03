defmodule WorkHandlerTest do
  use ExUnit.Case

  setup do
    # todo: this max_count should be virified here maybe
    WorkHandler.start_link(self(), 100) # 1 job queued, 0 in progress
    Queue.enqueue(:a)
    :ok
  end

  test "get first job" do
    assert WorkHandler.request_job() == :a
  end

  test "complete a job" do
    assert WorkHandler.request_job() == :a # 0 job queued, 1 in progress
    assert WorkHandler.complete_job(:a, [:b, :c]) == 0 # 2 job queued, 0 in progress
  end

  test "do multiple jobs" do
    assert WorkHandler.request_job() == :a         # 0 job queued, 1 in progress
    assert WorkHandler.complete_job(:a, [:b, :c]) == 0 # 2 job queued, 0 in progress
    assert WorkHandler.request_job() == :b         # 1 job queued, 1 in progress
    assert WorkHandler.request_job() == :c         # 0 job queued, 2 in progress
    assert WorkHandler.complete_job(:b ,[]) == 1       # 0 job queued, 1 in progress
    assert WorkHandler.complete_job(:c ,[]) == 0       # 0 job queued, 0 in progress
  end

  test "complete job even though there is none in progress" do
    assert_raise(
      RuntimeError, "a job was completed when no jobs in progress!",
      fn -> WorkHandler.complete_job(:a, [:b]) end
      )
  end

  test "should send completed message" do
    assert WorkHandler.request_job() == :a
    assert WorkHandler.complete_job(:a, [])
    # todo: this is weird
    assert_received {:done, _} # The reporting is done in the workers
  end
end