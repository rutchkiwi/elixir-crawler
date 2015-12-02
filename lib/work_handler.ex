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
		# TODO: when this is called, main process gets linked to all these children. This needs to run in it's own thread, so that it can be killed and it's children with it.
		# TODO: does children get killed when parent dies?
		Logger.info "crawler process going in #{inspect self()}"

		visited_pid = Visited.start_link()
		# Logger.info "started visited link #{inspect self()}"
		# :timer.sleep(30)
		queue_pid = Queue.start_link()
		# :timer.sleep(30)

		# :timer.sleep(30)
		results_pid = Results.start_link()

		WorkHandler.Completions.start_link(max_count, visited_pid, queue_pid, results_pid)

		uri = URI.parse(first_url)
	    host = uri.host

	    # TODO: add back multiple workes
	    # for n <- 1..2 do
	    worker_pid1 = Worker.start_link(fetcher, host, visited_pid, queue_pid, results_pid)
	    worker_pid2 = Worker.start_link(fetcher, host, visited_pid, queue_pid, results_pid)
	    worker_pid3 = Worker.start_link(fetcher, host, visited_pid, queue_pid, results_pid)
	    # end


		Logger.debug "start link is #{inspect self()}"


		Queue.enqueue(queue_pid, uri)
	    results = receive do
			{:done, urls} -> urls
		end
		Logger.debug "results received"


	    # Kill worker so that it does not print errors during the shutdown process
		# :timer.sleep(100)
		Process.unlink(worker_pid1)
		Process.unlink(worker_pid2)
		Process.unlink(worker_pid3)
	    Process.exit(worker_pid1, :kill)
	    Process.exit(worker_pid2, :kill)
	    Process.exit(worker_pid3, :kill)

		Logger.debug "workers are now killed"
	    
	    # todo: is this really how to do it? supervisor instead?
	    Visited.stop(visited_pid)
	    # Queue.stop()
	    Logger.info "done killing, returning"
	    results
	end

	# For workers
	def request_job(queue_pid) do
		# Logger.debug "job requested"
		job = Queue.dequeue(queue_pid) # blocks
		job
	end
end

defmodule WorkHandler.Completions do
	require Logger
	use GenServer

	defmodule State do
    	defstruct unfinished_jobs: 1, failures: %{}, max_count: nil, visited_pid: nil, queue_pid: nil, main_process: nil, results_pid: nil
  	end

	def start_link(max_count, visited_pid, queue_pid, results_pid) do
		# {unfinished jobs, failure counts, max_count}
		# todo: state should be a struct or something
		# Logger.warn("starting workhandler.completions link with visited: #{inspect(visited_pid)}")
		state = %State{max_count: max_count, visited_pid: visited_pid, queue_pid: queue_pid, main_process: self(), results_pid: results_pid}
		GenServer.start_link(WorkHandler.Completions, state, name: __MODULE__)
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

 	def handle_cast({:ignoring_job}, old_state) do
 		new_state = %State{old_state | unfinished_jobs: old_state.unfinished_jobs - 1}
 		Logger.debug("ignoring job. unfinished_jobs - 1 -> #{new_state.unfinished_jobs}")

		check_completed(new_state)

		{:noreply, new_state}
 	end

 	def handle_cast({:error_in_job, uri}, old_state) do
 		# {unfinished_jobs, failures, max_count, visited_pid} = state

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
		# {unfinished_jobs, failures, max_count, visited_pid} = state

		Visited.mark_visited(old_state.visited_pid, visited_uri)
		Logger.debug "job completion of #{visited_uri.path}. enqueing links: #{prettyfy_list_of_uris(new_uris)}."
		Enum.map(new_uris, fn uri -> Queue.enqueue(old_state.queue_pid, uri) end)

		# unfinished_jobs = unfinished_jobs + length(new_uris) - 1
 		new_state = %State{old_state | unfinished_jobs: 
 											old_state.unfinished_jobs + length(new_uris) - 1}

		Logger.debug("job completion. unfinished_jobs + #{length(new_uris)} - 1 -> #{new_state.unfinished_jobs}")
		check_completed(new_state)
		{:noreply, new_state}
	end


 	def check_completed(state) do
 		# todo: maybe size should be the size of results instead?
 		if state.unfinished_jobs <= 0 or Visited.size(state.visited_pid) >= state.max_count do
			Logger.debug "completed last job, sending done msg. workhandler #{inspect self()}"

			# We're done. knows too much
			send(state.main_process, {:done, Results.get_all_results(state.results_pid)})
			# Short circuit genserver and die immidietly
			Logger.debug "kill genserver workhandler #{inspect self()}"
			Process.exit(self(), :normal)
		end
	end

	defp prettyfy_list_of_uris(uris) do
		Enum.map(uris, fn uri -> uri.path end) |> Enum.join(", ")
	end
end


