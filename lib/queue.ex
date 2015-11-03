defmodule Queue do
	# use GenServer
	# external interface
	# require IEx

	def start_link() do
		counter_pid = Counter.start_link()
		Process.register(counter_pid, :queue_size_counter)

		{:ok, pid} = Task.start_link(&await_enqueue/0)
		Process.register(pid, __MODULE__)
		{:ok, pid}
	end

	def dequeue() do
		send(__MODULE__, {:dequeue, self()})
		# IO.puts "dequeing from process #{inspect __MODULE__}"
		receive do 
			{:dequeued, value} -> 
				Counter.decrement(:queue_size_counter)
				value
		end
	end

	def enqueue(e) do
		IO.puts "enqued #{inspect e}"
		Counter.increment(:queue_size_counter)
		send(__MODULE__, {:enqueue, e})
		:ok
	end

	def size() do
		Counter.get(:queue_size_counter)
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