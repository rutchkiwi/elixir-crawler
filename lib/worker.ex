defmodule Worker do
	def process_urls(fetcher, host) do
		uri = WorkHandler.request_job()
    IO.puts "worker about to start on #{inspect uri}"

    body = fetcher.(URI.to_string(uri))
    if body != nil do            
      Visited.mark_visited(uri)

      links = HtmlParser.get_links(body) |>
        Enum.map(&URI.parse/1) |>
        Enum.map(&_normalize_uri(&1, host))

      Results.report_visited_uri(uri)
      # IO.puts("visited #{URI.to_string(uri)}")
      WorkHandler.complete_job(uri, links)
      process_urls(fetcher, host)
      # nasty conditional logic with duplication
    else
      WorkHandler.complete_job(uri, [])
      process_urls(fetcher, host)
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