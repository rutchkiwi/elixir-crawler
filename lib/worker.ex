defmodule Worker do
  require Logger

	def process_urls(fetcher, host, id) do
    Logger.debug "worker #{id} requesting job"
    uri = WorkHandler.request_job()

    if Visited.visited?(uri) do
      Logger.debug "ignoring uri #{uri.path} because it's already been visited/"
      WorkHandler.ignoring_job()
      process_urls(fetcher, host, id)
    else
      Logger.debug "worker #{id} about to start on #{uri.host}#{uri.path}"

      body = fetcher.(URI.to_string(uri))
      if body != nil do            
        links = HtmlParser.get_links(body) |>
          Enum.map(&URI.parse/1) |>
          Enum.map(&_normalize_uri(&1, host))

        Results.report_visited_uri(uri)
        WorkHandler.complete_job(uri, links)
        process_urls(fetcher, host, id)
        # nasty conditional logic with duplication
      else
        WorkHandler.complete_job(uri, [])
        process_urls(fetcher, host, id)
      end
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
