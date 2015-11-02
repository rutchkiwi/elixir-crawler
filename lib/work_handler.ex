defmodule WorkHandler do
	use GenServer

	# for supervisor/ main caller
	def start_link(main_process) do
		Queue.start_link()
		GenServer.start_link(Counter, 0, name: :counter)
		Process.register(main_process, :main_process)
	end

	# blocking
	# main process is the only process who should call this!!! 
	# thats quite weird, todo: check that it actually is
	def crawl(first_url) do
		# todo: url is parsed multiple times, bad
		Queue.enqueue(URI.parse(first_url))
		receive do
			{:done, urls} -> urls
		end
	end

	# For workers

	def request_job() do
		job = Queue.dequeue() # blocks
		GenServer.cast(:counter, :increment)
		IO.puts "a job #{inspect job} was requested"
		job
	end

	def complete_job(new_uris) do
		Enum.map(new_uris, &Queue.enqueue/1)
		jobs_in_progress = GenServer.call(:counter, :decrement)
		# IO.puts "there are now #{jobs_in_progress} in progress"
		# should check that if there is nothing in the queue, and jobs is 0
		# then we're done
		if jobs_in_progress < 0 do
			raise "a job was completed when no jobs in progress!"
		end

		if 0 == jobs_in_progress  == Queue.size() do
			# We're done. knows too much
			send(:main_process, Results.get_all_results())
		end
		# weird return value
		jobs_in_progress
	end

end



defmodule Results do
	
	def start_link() do
		Task.start_link(&_wait/0, name: __MODULE__)
	end

	def report_visited_uri(uri) do
		send(__MODULE__, URI.to_string(uri))
	end

	def get_all_results() do
		send(__MODULE__, :give_results)
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
