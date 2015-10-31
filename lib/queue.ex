defmodule Queue do
	# use GenServer
	# external interface
	require IEx

	def start_link() do
		{:ok, pid} = Task.start_link(&await_enqueue/0)
		Process.register(pid, __MODULE__)
		{:ok, pid}
	end

	def dequeue() do
		send(__MODULE__, {:dequeue, self()})
		IO.puts "dequeing from process #{inspect __MODULE__}"
		receive do 
			{:dequeued, value} -> value
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