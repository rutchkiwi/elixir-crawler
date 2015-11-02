defmodule WorkHandler do
	use GenServer
	require IEx

	# for supervisor/ main caller
	def start_link(main_process) do
		Queue.start_link()
		Process.register(Counter.start_link(), :in_progress_counter)
		Process.register(main_process, :main_process)
		Results.start_link()
	end

	# blocking
	# main process is the only process who should call this!!! 
	# thats quite weird, todo: check that it actually is
	def crawl(first_url) do
		# todo: url is parsed multiple times, bad
		Queue.enqueue(URI.parse(first_url))
		IO.puts("now awaiting :done")
		receive do
			{:done, urls} -> urls
			_ -> raise "wtf!"
		end
	end

	# For workers

	def request_job() do
		job = Queue.dequeue() # blocks
		Counter.increment(:in_progress_counter)
		IO.puts "a job #{inspect job} was requested"
		job
	end

	def complete_job(new_uris) do
		Enum.map(new_uris, &Queue.enqueue/1)
		jobs_in_progress = Counter.decrement(:in_progress_counter)
		# IO.puts "there are now #{jobs_in_progress} in progress"
		# should check that if there is nothing in the queue, and jobs is 0
		# then we're done
		if jobs_in_progress < 0 do
			raise "a job was completed when no jobs in progress!"
		end

		IO.inspect 0 == jobs_in_progress  == Queue.size()
		if {0, 0} == {jobs_in_progress, Queue.size()} do
			IO.puts "done in WorkHandler"
			# We're done. knows too much
			send(:main_process, Results.get_all_results())
		end
		# weird return value
		jobs_in_progress
	end

end



defmodule Results do
	
	def start_link() do
		{:ok, pid} = Task.start_link(&_wait/0)
		Process.register(pid, __MODULE__)
	end

	def report_visited_uri(uri) do
		send(__MODULE__, URI.to_string(uri))
	end

	def get_all_results() do
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
