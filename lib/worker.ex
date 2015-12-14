defmodule Worker do
  require Logger

  defmodule Pids do
    defstruct visited: nil, queue: nil, completions: nil
  end

  def start_link(fetcher, host, visited_pid, queue_pid, completions_pid) do
    pids = %Pids{visited: visited_pid, queue: queue_pid, completions: completions_pid}
    {:ok, pid} = Task.start_link(fn -> Worker.process_urls(fetcher, host, pids) end )
    pid
  end

	def process_urls(fetcher, host, pids) do
    uri = WorkHandler.request_job(pids.queue)

    Process.flag :trap_exit, true
    # TODO: should be a task
    child_pid = spawn_link (fn -> work(fetcher, host, uri, pids.visited) end)
    receive do
      # Uhhh a bit weird to trap exits like this
      {:EXIT, child_pid, {:done, links}} ->
         WorkHandler.Completions.complete_job(pids.completions, uri, links)
      {:EXIT, child_pid, :ignoring} ->
          WorkHandler.Completions.ignoring_job(pids.completions)
      {:EXIT, child_pid, :http_error} ->
          Logger.debug "handling well-behaved http error."
          WorkHandler.Completions.error_in_job(pids.completions, uri)
      {:EXIT, child_pid, :normal} ->
          Logger.debug "normal exit: shutdown was triggered from parent process"
      {:EXIT, child_pid, error} ->
          Logger.warn "Handling an error in worker subprocess: #{inspect error}, #{Exception.format_exit(error)}"
         WorkHandler.Completions.error_in_job(pids.completions, uri)
      # todo!
      # after 10 -> :timeout
    end

    IO.write(".")
    process_urls(fetcher, host, pids)
  end

  def work(fetcher, host, uri, visited_pid) do
    if Visited.visited?(visited_pid, uri) do
      # Logger.debug "ignoring uri #{uri.path} because it's already been visited/"
      Process.exit(self(), :ignoring)
    else

      responseInfo = fetcher.(URI.to_string(uri))
      body = case responseInfo do
        {:ok, resp_body} -> resp_body
        :notfound -> Process.exit(self(), :ignoring)
        :error -> Process.exit(self(), :http_error)
      end

      links = HtmlParser.get_links(body) |>
        Enum.map(&URI.parse/1) |>
        Enum.map(&_normalize_uri(&1, host))

      Process.exit(self(), {:done, links})
    end
  end

  def _normalize_uri(uri, hostname) do
    if uri.host == nil and uri.path != nil and String.starts_with?(uri.path, "/") do
      uri = %{uri | host: hostname, scheme: "http"}
    end
    uri
  end

  def set_of_uris_to_strings(uri_set) do
    uri_set |>
      Enum.map(&URI.to_string/1) |>
      Enum.into(HashSet.new)  # There doesn't seem to be a nicer way to map on a set 
  end
end
