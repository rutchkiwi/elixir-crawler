defmodule Queue do
	require Logger

	# external interface

	def start_link() do
		{:ok, pid} = Task.start_link(&await_enqueue/0)
		Logger.info("started queue task, pid is #{inspect pid}. self is #{inspect self()}")
		pid
	end
	
	def dequeue(pid) do
		send(pid, {:dequeue, self()})
		receive do 
			{:dequeued, value} -> 
				value
		end
	end

	def enqueue(pid, e) do
		send(pid, {:enqueue, e})
		:ok
	end

	# implementation	 

	def await_enqueue() do
		receive do
			{:enqueue, e} -> await_dequeue(e)
		end
	end

	def await_dequeue(e) do
		receive do
			{:dequeue, sender} -> 
				send(sender, {:dequeued, e})
				await_enqueue()
		end
	end
end
