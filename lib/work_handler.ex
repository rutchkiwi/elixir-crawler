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
		Logger.info "started visited link #{inspect self()}"
		# :timer.sleep(30)
		Queue.start_link()
		# :timer.sleep(30)
		Process.register(self(), :main_process)
		# :timer.sleep(30)
		Results.start_link()

		WorkHandler.Completions.start_link(max_count, visited_pid)

		uri = URI.parse(first_url)
	    host = uri.host

	    # TODO: add back multiple workes
	    # for n <- 1..2 do
	    {:ok, worker_pid1} = Task.start_link(fn -> Worker.process_urls(fetcher, host, 1, visited_pid) end )
	    {:ok, worker_pid2} = Task.start_link(fn -> Worker.process_urls(fetcher, host, 2, visited_pid) end )
	    {:ok, worker_pid3} = Task.start_link(fn -> Worker.process_urls(fetcher, host, 3, visited_pid) end )
	    # end


		Logger.debug "start link is #{inspect self()}"


		Queue.enqueue(uri)
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
	    Queue.stop()
	    Logger.info "done killing, returning"
	    results
	end

	# For workers
	def request_job() do
		# Logger.debug "job requested"
		job = Queue.dequeue() # blocks
		job
	end
end

defmodule WorkHandler.Completions do
	require Logger
	use GenServer

	def start_link(max_count, visited_pid) do
		# {unfinished jobs, failure counts, max_count}
		# todo: state should be a struct or something
		Logger.warn("starting workhandler.completions link with visited: #{inspect(visited_pid)}")
		state = {1, %{}, max_count, visited_pid}
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

 	def handle_cast({:ignoring_job}, {unfinished_jobs, failures, max_count, visited_pid}) do
 		Logger.debug("ingoring job. unfinished_jobs before: #{unfinished_jobs}")
 		unfinished_jobs = unfinished_jobs - 1
 		Logger.debug("ingoring job. unfinished_jobs - 1 -> #{unfinished_jobs}")
		check_completed(unfinished_jobs, max_count, visited_pid)

		{:noreply, {unfinished_jobs, failures, max_count, visited_pid}}
 	end

 	def handle_cast({:error_in_job, uri}, state) do
 		{unfinished_jobs, failures, max_count, visited_pid} = state

 		failures_for_uri = Map.get(failures, uri, 0)
 		if failures_for_uri < 3 do
 			Logger.debug("error, trying again.")
 			Queue.enqueue(uri)
			{
				:noreply,
				{unfinished_jobs, Map.put(failures, uri, failures_for_uri + 1), max_count, visited_pid}
			}
 		else
 			# We already tried this url too many times, ignore
 			unfinished_jobs = unfinished_jobs - 1
			check_completed(unfinished_jobs, max_count, visited_pid)
 			Logger.debug("too many errors. unfinished_jobs - 1 -> #{unfinished_jobs}")
			{:noreply, state}
		end
 	end

	def handle_cast({:complete_job, visited_uri, new_uris},
					 state) do
		{unfinished_jobs, failures, max_count, visited_pid} = state

		Visited.mark_visited(visited_pid, visited_uri)
		Logger.debug "job completion of #{visited_uri.path}. enqueing links: #{prettyfy_list_of_uris(new_uris)}."
		Enum.map(new_uris, &Queue.enqueue/1)

		unfinished_jobs = unfinished_jobs + length(new_uris) - 1
		Logger.debug("job completion. unfinished_jobs + #{length(new_uris)} - 1 -> #{unfinished_jobs}")
		check_completed(unfinished_jobs, max_count, visited_pid)
		{:noreply, {unfinished_jobs, failures, max_count, visited_pid}}
	end


 	def check_completed(no_unfinished_jobs, max_count, visited_pid) do
 		# todo: maybe size should be the size of results instead?
 		if no_unfinished_jobs <= 0 or Visited.size(visited_pid) >= max_count do
			Logger.debug "completed last job, sending done msg. workhandler #{inspect self()}"

			# We're done. knows too much
			send(:main_process, {:done, Results.get_all_results()})
			# Short circuit genserver and die immidietly
			Logger.debug "kill genserver workhandler #{inspect self()}"
			Process.exit(self(), :normal)
		end
	end

	defp prettyfy_list_of_uris(uris) do
		Enum.map(uris, fn uri -> uri.path end) |> Enum.join(", ")
	end
end


