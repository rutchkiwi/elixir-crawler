defmodule Results do
	# TODO: message que will fill up
	# TODO: will miss messages if delivery is slow
	
	def start_link() do
		{:ok, pid} = Task.start_link(&_wait/0)
		pid
	end

	def report_visited_uri(pid, uri) do
		# Task.start(fn -> 
				send(pid, {:visited, URI.to_string(uri)})
		# 	end
		# )
		# :timer.sleep(20)
	end

	def get_all_results(pid) do
		send(pid, {:give_results, self()})
		receive do
			{:give_results_answer, all_results} -> all_results
		end
	end

	def _wait() do
		{caller, all_results} = receive do
			{:give_results, caller} -> {caller, _fetch_all_results(HashSet.new)}
		end
		send(caller, {:give_results_answer, all_results})
	end

	def _fetch_all_results(results) do
		receive do
			{:visited, url} -> _fetch_all_results(Set.put(results, url))
			after 0 -> results
		end
	end
end
