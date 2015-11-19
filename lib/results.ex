defmodule Results do
	# TODO: message que will fill up
	# TODO: will miss messages if delivery is slow
	
	def start_link() do
		{:ok, pid} = Task.start_link(&_wait/0)
		Process.register(pid, __MODULE__)
	end

	def report_visited_uri(uri) do
		send(__MODULE__, {:visited, URI.to_string(uri)})
	end

	def get_all_results() do
		# :timer.sleep(30)
		send(__MODULE__, {:give_results, self()})
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
