defmodule WorkerSupervisor do
  import Supervisor.Spec

  def start_link(fetcher, url_string, max_count, main_process) do
    uri = URI.parse(url_string)
    host = uri.host

    # shouldnt be restarted
    children = for n <- 1..10, do: worker(Task, [fn -> Worker.process_urls(fetcher, host, n) end ], id: n)

    WorkHandler.start_link(main_process, max_count)

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
