defmodule WorkerSupervisor do
  import Supervisor.Spec

  def start_link(fetcher, url_string, max_count, main_process) do
    uri = URI.parse(url_string)
    host = uri.host

    children = [
      worker(Task, [fn -> Worker.process_urls(fetcher, host, 1) end ], id: 1),
      worker(Task, [fn -> Worker.process_urls(fetcher, host, 2) end ], id: 2),
    ]
    WorkHandler.start_link(main_process, max_count)

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
