defmodule Queue do
	use GenServer

	# external interface
	def start_link() do
		GenServer.start_link(__MODULE__, :queue.new, name: __MODULE__)
	end

	def dequeue() do
		GenServer.call(__MODULE__, :dequeue)
	end

	def enqueue(e) do
		GenServer.cast(__MODULE__, {:enqueue, e})
	end

	# implementation

	def handle_call(:dequeue, _from, queue) do
		{status, queue} = :queue.out(queue)
		case status do
			{:value, _value} -> {:reply, status, queue}
			:empty -> {:reply, status, queue}
		end
	end

	def handle_cast({:enqueue, e}, queue) do
		{:noreply, :queue.in(e, queue)}
	end

	# def terminate(_reason, _) do
	# 	IO.puts "store terminating!"
	# end
end