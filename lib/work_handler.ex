defmodule WorkHandler do
	use GenServer

	def start_link(first_uri) do
		Queue.start_link()
		Queue.enqueue(first_uri)
		GenServer.start_link(Counter, 0, name: :counter)
	end

	def request_job() do
		job = Queue.dequeue() # blocks
		GenServer.cast(:counter, :increment)
		job
	end

	def complete_job(new_uris) do
		Enum.map(new_uris, &Queue.enqueue/1)
		jobs_in_progress = GenServer.call(:counter, :decrement_and_get)
		# IO.puts "there are now #{jobs_in_progress} in progress"
		# should check that if there is nothing in the queue, and jobs is 0
		# then we're done
		if jobs_in_progress < 0 do
			raise "a job was completed when no jobs in progress!"
		end
		jobs_in_progress
	end
end

defmodule Counter do
  use GenServer

  def handle_call(:decrement_and_get, _from, count) do
    {:reply, count - 1 , count - 1}
  end

  def handle_cast(:increment, count) do
    {:noreply, count + 1}
  end
end

defmodule Results do
	
	def start_link() do
		Task.start_link(&wait/0, name: __MODULE__)
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

	def wait() do
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
