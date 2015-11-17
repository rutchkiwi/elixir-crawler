defmodule FailureCountTest do
	use ExUnit.Case

  	setup_all do
    	FailureCounter.start_link()
    	:ok
  	end

  	test "simple" do
  		assert FailureCounter.increment_and_get("a") == 1
  		assert FailureCounter.increment_and_get("a") == 2
  		assert FailureCounter.increment_and_get("a") == 3
  	end
	
end