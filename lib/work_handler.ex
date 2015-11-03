defmodule WorkHandler do
	use GenServer
	require IEx

	# for supervisor/ main caller
	def start_link(main_process) do
		Visited.start_link()
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
			# _ -> raise "wtf!"
		end
	end

	# For workers

	def request_job() do
		job = Queue.dequeue() # blocks
		if Visited.visited?(job) do
			# ignore this url
			request_job()
		else
			Counter.increment(:in_progress_counter)
			# IO.puts "a job #{inspect job} was requested"
			job
		end
	end

	def complete_job(visited_uri, new_uris) do
		Visited.mark_visited(visited_uri)
		IO.puts("new uris found are #{inspect new_uris}")
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
			send(:main_process, {:done, Results.get_all_results()})
		end
		# weird return value
		jobs_in_progress
	end

end


