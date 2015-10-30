defmodule Queue do
	def initalize() do
		WorkerSupervisor.start_link()
	end
end

defmodule WorkerSupervisor do
  import Supervisor.Spec

  def start_link do
    children = [
      worker(Task, [fn -> Worker.process_urls("dummy fetcher", 1) end ], id: 1),
      worker(Task, [fn -> Worker.process_urls("dummy fetcher", 2) end ], id: 2),
      worker(Task, [fn -> Worker.process_urls("dummy fetcher", 3) end ], id: 3),
      worker(Queue, [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

defmodule Worker do
	def process_urls(fetcher, id) do
		IO.puts("worker #{id} processes url")
		if (:rand.uniform(15) == 1) do
			IO.puts("aaargggh in #{inspect id}")
			raise "boom!"
		end
	 	:timer.sleep(1000)
		process_urls(fetcher, id)
	end
end

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