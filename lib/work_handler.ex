defmodule WorkHandler do
	use GenServer
	require Logger

	# for supervisor/ main caller
	def start_link(main_process, max_count) do
		Agent.start_link(fn -> max_count end, name: :max_count)
		Visited.start_link()
		Queue.start_link()
		# Process.register(Counter.start_link(), :in_progress_counter)
		Process.register(Counter.start_link(), :unfinished_jobs)
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
		Counter.increment(:unfinished_jobs)
		Queue.enqueue(URI.parse(first_url))
		receive do
			{:done, urls} -> urls
		end
	end

	# For workers

	def request_job() do
		Logger.debug "job requestd"
		job = Queue.dequeue() # blocks
		if Visited.visited?(job) do
			# todo: get rid of this! nicer if everything done in complete job, or worker check if visited himself maybe (and call complete with soemthing else)
			Logger.debug "ignoring already visited #{job.host}, decrement unfinished to #{Counter.decrement(:unfinished_jobs)}"
			request_job()
		else
			job
		end
	end

	def complete_job(visited_uri, new_uris) do
		Visited.mark_visited(visited_uri)
		:timer.sleep(5)
		Counter.increment(:unfinished_jobs, length(new_uris))
		Logger.debug "job completion of #{visited_uri.path}. enqueing links: #{prettyfy_list_of_uris(new_uris)}."
		Enum.map(new_uris, &Queue.enqueue/1)
		no_unfinished_jobs = Counter.decrement(:unfinished_jobs)

		# should check that if there is nothing in the queue, and jobs is 0
		# then we're done
		# if jobs_in_progress < 0 do
		# 	raise "a job was completed when no jobs in progress!"
		# end

		:timer.sleep(5)
		if no_unfinished_jobs == 0 or Visited.size >= Agent.get(:max_count, &(&1)) do
			Logger.debug "completed last job, sending done msg."
			# todo: seems like we'll deadlock when an already visited url is the only
			# thing added here, since we only check this on complete_job.
			# maybe it should be checked in reuqest_job as well? add test

			# We're done. knows too much
			send(:main_process, {:done, Results.get_all_results()})
		end
	end

	defp prettyfy_list_of_uris(uris) do
		Enum.map(uris, fn uri -> uri.path end) |> Enum.join(", ")
	end

end


