defmodule Crawler.CLI do
  def main([url]) do
    urls = Crawler.Main.start(&HttpFetcher.fetch/1, url)
    IO.puts "found urls #{inspect(urls)}"
  end
end

# defmodule Crawler.Main do
# 	def crawl(fetcher_func, url) do
# 		body = fetcher_func.(url)
# 		links = HtmlParser.get_links(body)
# 		rest = Enum.map(links, &crawl(fetcher_func, &1))
# 		[url | List.flatten(rest)]
# 	end
# end

defmodule Crawler.Main do

	require IEx

	def start(fetcher, url_string) do
		uri = URI.parse(url_string)
		host = uri.host
		crawl(fetcher, HashSet.new, [uri], host)
	end

	def crawl(_, visited, [], _) do
		visited
	end

	def crawl(fetcher_func, visited, queue, host) do
		[uri | rest] = queue
		# IO.puts "host #{host} uri path #{inspect(uri.path)}"
		if uri.host == nil and String.starts_with?(uri.path, "/") do
			uri = %{uri | host: host}
		end
		if uri.scheme == nil do
			uri = %{uri | scheme: "http"}
		end
		if Set.member?(visited, URI.to_string(uri)) do
			# IO.puts("already visited #{uri}")
			crawl(fetcher_func, visited, rest, host)	
		else
			body = fetcher_func.(URI.to_string(uri))
			if body == nil do
				# IO.puts("body was nil for #{inspect(uri)}")
				crawl(fetcher_func, visited, rest, host)
			else
				link_url_strings = HtmlParser.get_links(body)
				link_uris = Enum.map(link_url_strings, &URI.parse/1)
				# IO.inspect(link_uris)	
				crawl(fetcher_func, Set.put(visited, URI.to_string(uri)), rest ++ link_uris, host)
			end
		end
	end
end

defmodule HtmlParser do
	def get_links(nil) do
		[]
	end

	def get_links(body) do
		# IO.puts "parsing body #{body}"
		Floki.attribute(body, "a", "href")
	end
end

defmodule HttpFetcher do
	def fetch(url) do
		IO.puts "fetching url #{inspect(url)}"
		case HTTPoison.get(url) do
			{:ok, resp} -> resp.body
			{:error, _} -> nil
		end
	end
end