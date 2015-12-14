defmodule WorkHandler do
	use GenServer
	require Logger

	# for supervisor/ main caller

	# TOOD: this is a bit weird. separate setup, cleanup and work cleanly 

	def start_and_crawl(max_count, first_url, fetcher) do
		Logger.info "about to start crawler thread"
		main_task = Task.async(
			WorkHandler, :_start_and_crawl, [max_count, first_url, fetcher])
		Task.await(main_task)
	end

	def _start_and_crawl(max_count, first_url, fetcher) do
		# TODO: this is kinda like a supervisor, should things be restartable?

		Logger.info "crawler process going in #{inspect self()}"

		visited_pid = Visited.start_link()

		queue_pid = Queue.start_link()

		completions_pid = WorkHandler.Completions.start_link(max_count, visited_pid, queue_pid)

		uri = URI.parse(first_url)
	    host = uri.host

	    # TODO: add back multiple workes
	    for _ <- 1..10 do
		    Worker.start_link(fetcher, host, visited_pid, queue_pid, completions_pid)
	    end

		Logger.debug "start link is #{inspect self()}"

		Queue.enqueue(queue_pid, uri)
	    results = receive do
			{:done, urls} -> urls
		end
		Logger.debug "results received"

	    results
	end

	# For workers
	def request_job(queue_pid) do
		job = Queue.dequeue(queue_pid) # blocks
		job
	end
end

defmodule WorkHandler.Completions do
	require Logger
	use GenServer

	defmodule State do
    	defstruct unfinished_jobs: 1, failures: %{}, max_count: nil, results: HashSet.new, visited_pid: nil, queue_pid: nil, main_process: nil
  	end

	def start_link(max_count, visited_pid, queue_pid) do
		Logger.debug("starting workhandler.completions link with visited: #{inspect(visited_pid)}")
		state = %State{max_count: max_count, visited_pid: visited_pid, queue_pid: queue_pid, main_process: self()}
		{:ok, pid} = GenServer.start_link(WorkHandler.Completions, state)
		pid
	end

	### For workers ################

 	def ignoring_job(pid) do
 		GenServer.cast(pid, {:ignoring_job})
 	end

 	def error_in_job(pid, uri) do
 		GenServer.cast(pid, {:error_in_job, uri})
 	end

	def complete_job(pid, visited_uri, new_uris) do
		GenServer.cast(pid, {:complete_job, visited_uri, new_uris})
	end

 	### implemention ###############

 	def handle_cast({:ignoring_job}, old_state) do
 		new_state = %State{old_state | unfinished_jobs: old_state.unfinished_jobs - 1}
 		Logger.debug("ignoring job. unfinished_jobs - 1 -> #{new_state.unfinished_jobs}")

		check_completed(new_state)

		{:noreply, new_state}
 	end

 	def handle_cast({:error_in_job, uri}, old_state) do
 		failures_for_uri = Map.get(old_state.failures, uri, 0)
 		if failures_for_uri < 3 do
 			Logger.debug("error, trying again.")
 			Queue.enqueue(old_state.queue_pid, uri)
			{
				:noreply,
				# {unfinished_jobs, Map.put(failures, uri, failures_for_uri + 1), max_count, visited_pid}
				%State{old_state | failures: Map.put(old_state.failures, uri, failures_for_uri + 1)}
			}
 		else
 			# We already tried this url too many times, ignore
 			# unfinished_jobs = unfinished_jobs - 1
	 		new_state = %State{old_state | unfinished_jobs: old_state.unfinished_jobs - 1}

			check_completed(new_state)
 			Logger.debug("too many errors. unfinished_jobs - 1 -> #{new_state.unfinished_jobs}")
			{:noreply, new_state}
		end
 	end

	def handle_cast({:complete_job, visited_uri, new_uris}, old_state) do
		Visited.mark_visited(old_state.visited_pid, visited_uri)

		Logger.debug "job completion of #{visited_uri.path}. enqueing links: #{prettyfy_list_of_uris(new_uris)}."
		Enum.map(new_uris, fn uri -> Queue.enqueue(old_state.queue_pid, uri) end)

 		new_state = %State{old_state | unfinished_jobs: 
 											old_state.unfinished_jobs + length(new_uris) - 1,
 									 	results:
 									 		Set.put(old_state.results, URI.to_string(visited_uri))}

		Logger.debug("job completion. unfinished_jobs + #{length(new_uris)} - 1 -> #{new_state.unfinished_jobs}")
		check_completed(new_state)
		{:noreply, new_state}
	end


 	def check_completed(state) do
 		# todo: maybe size should be the size of results instead?
 		if state.unfinished_jobs <= 0 or Visited.size(state.visited_pid) >= state.max_count do
			Logger.debug "completed last job, sending done msg. workhandler #{inspect self()}"

			# We're done. knows too much
			send(state.main_process, {:done, state.results})
			# Short circuit genserver and die immidietly, so that we can't report doneness twice
			Logger.debug "kill genserver workhandler #{inspect self()}"
			Process.exit(self(), :normal)
		end
	end

	defp prettyfy_list_of_uris(uris) do
		Enum.map(uris, fn uri -> uri.path end) |> Enum.join(", ")
	end
end


