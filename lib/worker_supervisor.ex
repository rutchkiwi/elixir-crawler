defmodule WorkerSupervisor do
  import Supervisor.Spec

  def start_link(fetcher, url_string, main_process) do
    uri = URI.parse(url_string)
    host = uri.host

    children = [
      worker(Task, [fn -> Worker.process_urls(fetcher, host, 1) end ], id: 1),
      # worker(Task, [fn -> Worker.process_urls(fetcher, 2) end ], id: 2),
      # worker(Task, [fn -> Worker.process_urls(fetcher, 3) end ], id: 3),
    ]
    WorkHandler.start_link(main_process)

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
