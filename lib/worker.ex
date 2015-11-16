defmodule Worker do
  require Logger

	def process_urls(fetcher, host, id) do

    
    Logger.debug "worker boss #{id} requesting job"
    uri = WorkHandler.request_job()

    # Process.flag :trap_exit, true
    caller = self()
    {:ok, child_pid} = Task.start_link(fn -> work(fetcher, host, uri, caller) end)
    Logger.info "self = #{inspect self()}"
    receive do
      # _ ->
        # Logger.error "catchall clause"
      {:done, links} ->
        Logger.info("worker boss comleting job")
         WorkHandler.complete_job(uri, links)
      {:ignoring} -> 
          WorkHandler.ignoring_job()
      {:EXIT, child_pid, :exit} ->
      #   # todo: should fail it
        # Logger.warn(reason)
         WorkHandler.ignoring_job()
      # todo!
      # after 10 -> :timeout
    end

    process_urls(fetcher, host, id)
  end

  def work(fetcher, host, uri, caller) do
    Logger.info "caller = #{inspect caller}"
    if Visited.visited?(uri) do
      Logger.debug "ignoring uri #{uri.path} because it's already been visited/"
      send(caller, {:ignoring})
    else
      Logger.debug "worker subprocess about to start on #{uri.host}#{uri.path}"

      body = fetcher.(URI.to_string(uri))
      if body == nil, do: raise "fetching url gave ni, error"            

      links = HtmlParser.get_links(body) |>
        Enum.map(&URI.parse/1) |>
        Enum.map(&_normalize_uri(&1, host))

      # todo: seems like race conditions possible if report_visited_uri is too slow
      Results.report_visited_uri(uri)
      Logger.debug "send #{inspect caller} done signal with #{inspect links}"
      send(caller, {:done, links})
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
