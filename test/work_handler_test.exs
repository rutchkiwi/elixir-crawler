defmodule WorkHandlerQueTest do
  use ExUnit.Case

  setup do
    WorkHandler.start_link(:a) # 1 job queued, 0 in progress
    :ok
  end

  test "queue: get first job" do
    assert WorkHandler.request_job() == :a
  end

  test "queue: complete a job" do
    assert WorkHandler.request_job() == :a # 0 job queued, 1 in progress
    assert WorkHandler.complete_job([:b, :c]) == 0 # 2 job queued, 0 in progress
  end

  test "queue: do multiple jobs" do
    assert WorkHandler.request_job() == :a # 0 job queued, 1 in progress
    assert WorkHandler.complete_job([:b, :c]) == 0 # 2 job queued, 0 in progress
    assert WorkHandler.request_job() == :b # 1 job queued, 1 in progress
    assert WorkHandler.request_job() == :c # 0 job queued, 2 in progress
    assert WorkHandler.complete_job([]) == 1 # 0 job queued, 1 in progress
    assert WorkHandler.complete_job([]) == 0 # 0 job queued, 0 in progress
  end

  test "complete job even though there is none in progress" do
    assert_raise(
      RuntimeError, "a job was completed when no jobs in progress!",
      fn -> WorkHandler.complete_job([:b]) end
      )
  end
end