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