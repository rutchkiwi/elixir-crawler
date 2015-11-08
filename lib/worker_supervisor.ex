defmodule WorkerSupervisor do
  import Supervisor.Spec

  def start_link(fetcher, url_string, max_count, main_process) do
    uri = URI.parse(url_string)
    host = uri.host

    children = [
      worker(Task, [fn -> Worker.process_urls(fetcher, host) end ], id: 1),
      # worker(Task, [fn -> Worker.process_urls(fetcher, host) end ], id: 2),
      # worker(Task, [fn -> Worker.process_urls(fetcher, host) end ], id: 3),
      # worker(Task, [fn -> Worker.process_urls(fetcher, host) end ], id: 4),
      # worker(Task, [fn -> Worker.process_urls(fetcher, host) end ], id: 5),
      # worker(Task, [fn -> Worker.process_urls(fetcher, host) end ], id: 6),
      # worker(Task, [fn -> Worker.process_urls(fetcher, host) end ], id: 7),
    ]
    WorkHandler.start_link(main_process, max_count)

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
