defmodule Visited do
	require Logger
	
	####### interface #######
	
	def start_link() do
		{:ok, pid} = Task.start(Visited, :run, [HashSet.new])
		Logger.info("started visited task, pid is #{inspect pid}. self is #{inspect self()}")
		# :timer.sleep(10)
		if ({true, nil} == {Process.alive?(pid), Process.whereis(__MODULE__)}) do
			Process.register(pid, __MODULE__)
		else
			Logger.warn("found a pre-exisiting visited process. pid for that one is #{inspect Process.whereis(__MODULE__)}. self is #{inspect self()}")
			raise "WTF!!"
		end
	end

	def stop() do
		pid = Process.whereis(__MODULE__)
		Process.unlink(pid)
		Process.exit(pid, :kill)
	end

	def mark_visited(url) do
		send(__MODULE__, {:mark_visited, url})
	end

	def get_visited() do
		# make a random id to make sure we don't answer someone else. neccessary? prob not?? but safe
		question_id = :random.uniform(1000000000)
		send(__MODULE__, {:get_visited, self, question_id})
		receive do
			{:get_visited_reply, ^question_id, visited} -> visited
		end
	end

	def visited?(url) do
		Set.member?(get_visited(), url)
	end

	def size() do
		Set.size(get_visited())
	end

	####### implementation #######

	def run(visited_set) do
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