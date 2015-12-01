defmodule Queue do
	require Logger

	# external interface

	def start_link() do
		{:ok, pid} = Task.start_link(&await_enqueue/0)
		if Process.whereis(__MODULE__) != nil do
			Logger.warn "found a pre-exisiting queue process. pid for that one is #{inspect Process.whereis(__MODULE__)}. self is #{inspect self()}"
			raise "TOO MANY QUEUES WTF!!"
		end
		Process.register(pid, __MODULE__)
		Logger.info("started visited task, pid is #{inspect pid}. self is #{inspect self()}")
		{:ok, pid}
	end

	def stop() do
		pid = Process.whereis(__MODULE__)
		# todo: this is weird
		Process.unlink(pid)
		Process.unregister(__MODULE__)
		Process.exit(pid, :kill)
	end

	def dequeue() do
		send(__MODULE__, {:dequeue, self()})
		receive do 
			{:dequeued, value} -> 
				value
		end
	end

	def enqueue(e) do
		send(__MODULE__, {:enqueue, e})
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
