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

	def is_visited(url) do
		{:ok, pid} = get_pid()
		question_id = :random.uniform(1000000000)
		send(pid, {:visited?, self, question_id, url})
		receive do
			{:visited_reply, ^question_id, visited} -> visited
		end
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
			{:mark_visited, url} -> run(Set.put(visited_set, url))
			{:visited?, sender, id, url} -> 
				send(sender, {:visited_reply, id, Set.member?(visited_set, url)})
				run(visited_set)
		end
	end
end