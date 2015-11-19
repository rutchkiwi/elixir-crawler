defmodule Worker do
  require Logger

	def process_urls(fetcher, host, id) do

    
    # Logger.info "worker boss #{id} with pid #{inspect self()} requesting job"
    uri = WorkHandler.request_job()

    Process.flag :trap_exit, true
    spawn_link (fn -> work(fetcher, host, uri) end)
    receive do
      # Uhhh a bit weird to trap exits like this
      {:EXIT, _child_pid, {:done, links}} ->
         WorkHandler.complete_job(uri, links)
      {:EXIT, _child_pid, :ignoring} ->
          WorkHandler.ignoring_job()
      {:EXIT, _child_pid, :http_error} ->
          Logger.debug "handling well-behaved http error."
          WorkHandler.error_in_job(uri)
      {:EXIT, _child_pid, error} ->
          Logger.warn "Handling an error in worker subprocess: #{inspect error}"
         WorkHandler.error_in_job(uri)
      # todo!
      # after 10 -> :timeout
    end

    IO.write(".")
    process_urls(fetcher, host, id)
  end

  def work(fetcher, host, uri) do
    if Visited.visited?(uri) do
      # Logger.debug "ignoring uri #{uri.path} because it's already been visited/"
      Process.exit(self(), :ignoring)
    else
      # Logger.debug "worker subprocess about to start on #{uri.host}#{uri.path}"

      responseInfo = fetcher.(URI.to_string(uri))
      body = case responseInfo do
        {:ok, resp_body} -> resp_body
        :notfound -> Process.exit(self(), :ignoring)
        :error -> Process.exit(self(), :http_error)
      end

      links = HtmlParser.get_links(body) |>
        Enum.map(&URI.parse/1) |>
        Enum.map(&_normalize_uri(&1, host))

      # todo: seems like race conditions possible if report_visited_uri is too slow
      Results.report_visited_uri(uri)
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
