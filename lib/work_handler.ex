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
		job
	end

 	def ignoring_job() do
		check_completed(Counter.decrement(:unfinished_jobs))
 	end

 	def check_completed(no_unfinished_jobs) do
 		if no_unfinished_jobs <= 0 or Visited.size >= Agent.get(:max_count, &(&1)) do
			Logger.debug "completed last job, sending done msg."

			# We're done. knows too much
			send(:main_process, {:done, Results.get_all_results()})
		end
	end

	def complete_job(visited_uri, new_uris) do
		Visited.mark_visited(visited_uri)
		# :timer.sleep(5)
		Counter.increment(:unfinished_jobs, length(new_uris))
		Logger.debug "job completion of #{visited_uri.path}. enqueing links: #{prettyfy_list_of_uris(new_uris)}."
		Enum.map(new_uris, &Queue.enqueue/1)

		check_completed(Counter.decrement(:unfinished_jobs))
	end

	defp prettyfy_list_of_uris(uris) do
		Enum.map(uris, fn uri -> uri.path end) |> Enum.join(", ")
	end
end


