defmodule WorkHandler do
	use GenServer
	require Logger

	# for supervisor/ main caller

	# TOOD: this is a bit weird. separate setup, cleanup and work cleanly 

	def start_link(main_process, max_count, first_url, fetcher) do
		Agent.start_link(fn -> max_count end, name: :max_count)
		# :timer.sleep(30)
		Visited.start_link()
		# :timer.sleep(30)
		Queue.start_link()
		# :timer.sleep(30)
		Process.register(main_process, :main_process)
		# :timer.sleep(30)
		Results.start_link()
		# :timer.sleep(30)

		WorkHandler.Completions.start_link()

		uri = URI.parse(first_url)
	    host = uri.host

	    # TODO: add back multiple workes
	    # for n <- 1..2 do
	    {:ok, worker_pid1} = Task.start_link(fn -> Worker.process_urls(fetcher, host, 1) end )
	    {:ok, worker_pid2} = Task.start_link(fn -> Worker.process_urls(fetcher, host, 2) end )
	    {:ok, worker_pid3} = Task.start_link(fn -> Worker.process_urls(fetcher, host, 3) end )
	    # end

		# :timer.sleep(30)
		Queue.enqueue(uri)
	    results = receive do
			{:done, urls} -> urls
		end

	    # Kill worker so that it does not print errors during the shutdown process
	    Process.exit(worker_pid1, :kill)
	    Process.exit(worker_pid2, :kill)
	    Process.exit(worker_pid3, :kill)

	    results
	end

	# For workers
	def request_job() do
		Logger.debug "job requested"
		job = Queue.dequeue() # blocks
		job
	end
end

defmodule WorkHandler.Completions do
	require Logger
	use GenServer

	def start_link() do
		#                               {unfinished jobs, failure counts}
		GenServer.start_link(WorkHandler.Completions, {1, %{}}, name: __MODULE__)
	end

	### For workers ################

 	def ignoring_job() do
 		GenServer.cast(__MODULE__, {:ignoring_job})
 	end

 	def error_in_job(uri) do
 		GenServer.cast(__MODULE__, {:error_in_job, uri})
 	end

	def complete_job(visited_uri, new_uris) do
		GenServer.cast(__MODULE__, {:complete_job, visited_uri, new_uris})
	end

 	### implemention ###############

 	def handle_cast({:ignoring_job}, {unfinished_jobs, failures}) do
 		unfinished_jobs = unfinished_jobs - 1
 		Logger.debug("ingoring job. unfinished_jobs - 1 -> #{unfinished_jobs}")
		check_completed(unfinished_jobs)
		{:noreply, {unfinished_jobs, failures}}
 	end

 	def handle_cast({:error_in_job, uri}, {unfinished_jobs, failures}) do
 		failures_for_uri = Map.get(failures, uri, 0)
 		if failures_for_uri < 3 do
 			Logger.debug("error, trying again.")
 			Queue.enqueue(uri)
			{
				:noreply,
				{unfinished_jobs, Map.put(failures, uri, failures_for_uri + 1)}
			}
 		else
 			# We already tried this url too many times, ignore
 			unfinished_jobs = unfinished_jobs - 1
			check_completed(unfinished_jobs)
 			Logger.debug("too many errors. unfinished_jobs - 1 -> #{unfinished_jobs}")
			{:noreply, {unfinished_jobs, failures}}
		end
 	end

	def handle_cast({:complete_job, visited_uri, new_uris}, {unfinished_jobs, failures}) do
		Visited.mark_visited(visited_uri)
		Logger.debug "job completion of #{visited_uri.path}. enqueing links: #{prettyfy_list_of_uris(new_uris)}."
		Enum.map(new_uris, &Queue.enqueue/1)

		unfinished_jobs = unfinished_jobs + length(new_uris) - 1
		Logger.debug("job completion. unfinished_jobs + #{length(new_uris)} - 1 -> #{unfinished_jobs}")
		check_completed(unfinished_jobs)
		{:noreply, {unfinished_jobs, failures}}
	end


 	def check_completed(no_unfinished_jobs) do
 		if no_unfinished_jobs <= 0 or Visited.size >= Agent.get(:max_count, &(&1)) do
			Logger.debug "completed last job, sending done msg."

			# We're done. knows too much
			send(:main_process, {:done, Results.get_all_results()})
			# Short circuit genserver and die immidietly
			Process.exit(self(), :normal)
		end
	end

	defp prettyfy_list_of_uris(uris) do
		Enum.map(uris, fn uri -> uri.path end) |> Enum.join(", ")
	end
end


