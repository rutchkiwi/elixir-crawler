defmodule Visited do
	require Logger
	
	####### interface #######
	
	def start_link() do
		{:ok, pid} = Task.start_link(Visited, :run, [HashSet.new])
		Logger.info("starting visited task, pid is #{inspect pid}. self is #{inspect self()}")
		pid
	end

	def mark_visited(pid, url) do
		send(pid, {:mark_visited, url})
	end

	def get_visited(pid) do
		# make a random id to make sure we don't answer someone else. neccessary? prob not?? but safe
		question_id = :random.uniform(1000000000)
		send(pid, {:get_visited, self, question_id})
		receive do
			{:get_visited_reply, ^question_id, visited} -> visited
		end
	end

	def visited?(pid, url) do
		Set.member?(get_visited(pid), url)
	end

	def size(pid) do
		Set.size(get_visited(pid))
	end

	####### implementation #######

	def run(visited_set) do
		#TODO: genserver?
		receive do
			{:mark_visited, url} ->
				run(Set.put(visited_set, url))
			{:get_visited, sender, id} -> 
				send(sender, {:get_visited_reply, id, visited_set})
				run(visited_set)
		end
		Logger.info("ran visited task")
	end
end