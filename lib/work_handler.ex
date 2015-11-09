defmodule WorkHandler do
	use GenServer
	require Logger

	# for supervisor/ main caller
	def start_link(main_process, max_count) do
		Agent.start_link(fn -> max_count end, name: :max_count)
		Visited.start_link()
		Queue.start_link()
		Process.register(Counter.start_link(), :in_progress_counter)
		Process.register(main_process, :main_process)
		Results.start_link()

		GenServer.start_link(WorkHandler, [])
	end

	# blocking
	# main process is the only process who should call this!!! 
	# thats quite weird, todo: check that it actually is
	def crawl(first_url) do
		# todoL: this is a really stupid way to do this. should be baked in 
		# somewhere?
		# todo: url is parsed multiple times, bad
		Queue.enqueue(URI.parse(first_url))
		receive do
			{:done, urls} -> urls
		end
	end

	# For workers
	# todo: both of these must be run inside the process, otherwise race conditions can occur

	def request_job() do
		Logger.debug "RJ: job requestd"
		job = Queue.dequeue() # blocks
		if Visited.visited?(job) do
			# ignore this url
			request_job()
		else
			Logger.debug "RJ: job found, counter will be incremented"
			Counter.increment(:in_progress_counter)
			# IO.puts "a job #{inspect job} was requested"
			job
		end
	end

	def complete_job(visited_uri, new_uris) do
		Logger.debug "CJ: job completion of #{visited_uri.path}"
		Visited.mark_visited(visited_uri)
		:timer.sleep(5)
		Logger.debug "CJ: enqueing jobs #{inspect new_uris}"
		Enum.map(new_uris, &Queue.enqueue/1)
		Logger.debug "CJ: decremeting and getting new value of in_progress_counter"
		jobs_in_progress = Counter.decrement(:in_progress_counter)
		# IO.puts "there are now #{jobs_in_progress} in progress"
		# should check that if there is nothing in the queue, and jobs is 0
		# then we're done
		if jobs_in_progress < 0 do
			raise "a job was completed when no jobs in progress!"
		end

		:timer.sleep(5)
		Logger.debug "CJ: checking queue size"
		queue_size = Queue.size()
		Logger.debug "CJ: deciding on doneness"
		if {0, 0} == {jobs_in_progress, queue_size} or 
			Visited.size >= Agent.get(:max_count, &(&1)) do
			Logger.warn "completed last job, sending done msg. based on #{inspect {jobs_in_progress, queue_size}}"
			# todo: seems like we'll deadlock when an already visited url is the only
			# thing added here, since we only check this on complete_job.
			# maybe it should be checked in reuqest_job as well? add test
			# IO.puts "done in WorkHandler"
			# We're done. knows too much
			send(:main_process, {:done, Results.get_all_results()})
		end
		# weird return value
		jobs_in_progress
	end

end


