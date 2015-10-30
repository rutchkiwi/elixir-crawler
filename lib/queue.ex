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
		res = {:ok, pid} = GenServer.start_link(__MODULE__, ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k"])
		Process.register(pid, __MODULE__)
		res
	end

	def dequeue() do
		{:ok, pid} = get_pid()
		GenServer.call(pid, :dequeue)
	end
	
	# def save_value(pid, value) do
	# 	IO.puts "save to store pid #{inspect(pid)}"
	# 	GenServer.cast(pid, {:save_value, value})
	# ende

	# def get_value(pid) do
	# 	GenServer.call(pid, :get_value)
	# end

	# implementation

	def get_pid() do
		pid = Process.whereis(__MODULE__)
		if pid != nil do
			{:ok, pid} 
		else 
			{:error}
		end
	end

	def handle_call(:dequeue, _from, [head | tail]) do
		{:reply, head, tail}
	end

	# def handle_cast({:save_value, value}, _current_value) do
	# 	IO.puts "store saving its contents"
	# 	{:noreply, value}
	# end

	# def terminate(_reason, _) do
	# 	IO.puts "store terminating!"
	# end
end