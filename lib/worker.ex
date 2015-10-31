defmodule Worker do
	def process_urls(fetcher, host, id) do
		uri = Queue.dequeue()
    IO.puts "dequed uri #{inspect uri}"

    body = fetcher.(URI.to_string(uri))
    if body != nil do            # IO.puts("body was nil for #{inspect(uri)}")
      Visited.mark_visited(uri)

      HtmlParser.get_links(body) |>
        Enum.map(&URI.parse/1) |>
        Enum.map(&_normalize_uri(&1, host)) |>
        Enum.map(fn uri -> Queue.enqueue(uri) end)

      IO.puts("visited #{URI.to_string(uri)}")
    end
    process_urls(fetcher, host, id)
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