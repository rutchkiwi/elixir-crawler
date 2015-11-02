defmodule WorkerSupervisor do
  import Supervisor.Spec

  def start_link(fetcher, url_string) do
    uri = URI.parse(url_string)
    host = uri.host
    WorkHandler.start_link(uri)

    children = [
      worker(Task, [fn -> Worker.process_urls(fetcher, host, 1) end ], id: 1),
      # worker(Task, [fn -> Worker.process_urls(fetcher, 2) end ], id: 2),
      # worker(Task, [fn -> Worker.process_urls(fetcher, 3) end ], id: 3),
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
