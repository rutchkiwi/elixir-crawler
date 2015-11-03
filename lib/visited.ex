defmodule Visited do
	
	####### interface #######
	
	def start_link() do
		{:ok, pid} = Task.start_link(Visited, :run, [HashSet.new])
		Process.register(pid, __MODULE__)
	end

	def mark_visited(url) do
		{:ok, pid} = get_pid()
		send(pid, {:mark_visited, url})
	end

	def get_visited() do
		{:ok, pid} = get_pid()
		# make a random id to make sure we don't answer someone else. neccessary? prob not?? but safe
		question_id = :random.uniform(1000000000)
		send(pid, {:get_visited, self, question_id})
		receive do
			{:get_visited_reply, ^question_id, visited} -> visited
		end
	end

	def visited?(url) do
		Set.member?(get_visited(), url)
	end

	####### implementation #######

	def get_pid() do
		pid = Process.whereis(__MODULE__)
		if pid != nil do
			{:ok, pid} 
		else 
			{:error}
		end
	end

	def run(visited_set) do
		receive do
			{:mark_visited, url} ->
				run(Set.put(visited_set, url))
			{:get_visited, sender, id} -> 
				send(sender, {:get_visited_reply, id, visited_set})
				run(visited_set)
		end
	end
end