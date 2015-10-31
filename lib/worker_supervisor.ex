defmodule WorkerSupervisor do
  import Supervisor.Spec

  def start_link(fetcher, hostname) do
    children = [
      worker(Task, [fn -> Worker.process_urls(fetcher, hostname, 1) end ], id: 1),
      # worker(Task, [fn -> Worker.process_urls(fetcher, 2) end ], id: 2),
      # worker(Task, [fn -> Worker.process_urls(fetcher, 3) end ], id: 3),
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
    Queue.start_link()
  end
end
