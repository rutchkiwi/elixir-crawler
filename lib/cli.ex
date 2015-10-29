defmodule Crawler.CLI do
	def main([url, max_count_str]) do
		{_, tic, _} = :os.timestamp
		{max_count, ""} = Integer.parse(max_count_str)
		urls = Crawler.Main.start(&HttpFetcher.fetch/1, url, max_count)
		{_, toc, _} = :os.timestamp
		time = toc - tic
		IO.puts "found urls #{inspect(urls)} in #{time} s"
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

	def start(fetcher, url_string, max_count \\ 20) do
		uri = URI.parse(url_string)
		host = uri.host
		Visited.start_link()
		crawl(fetcher, [uri], host, 0, max_count)
	end

  	def crawl(_, [], _, _, _) do
  		Visited.get_visited() |>
  			Enum.map(&URI.to_string/1) |>
  			Enum.into(HashSet.new) # There doesn't seem to be a nicer way to map on a set 
    end

	def crawl(fetcher_func, queue, host, count, max_count) do
		[uri | rest] = queue
		visited = Visited.get_visited()
		if Set.member?(visited, uri) or uri.host != host do
			# IO.puts("ignoring #{uri}")
			# ignore this url
			crawl(fetcher_func, rest, host, count, max_count)	
		else
			body = fetcher_func.(URI.to_string(uri))
			if body == nil do
				# IO.puts("body was nil for #{inspect(uri)}")
				crawl(fetcher_func, rest, host, count, max_count)
			else
				link_uris = HtmlParser.get_links(body) |>
					Enum.map(&URI.parse/1) |>
					Enum.map(&_normalize_uri(&1, host))

				# IO.puts "Adding url #{URI.to_string(uri)} to visited list (#{Set.size(visited)})"
				Visited.mark_visited(uri)
				crawl(fetcher_func, rest ++ link_uris, host, count+1, max_count)
			end
		end
	end

	def _normalize_uri(uri, hostname) do
		if uri.host == nil and uri.path != nil and String.starts_with?(uri.path, "/") do
			uri = %{uri | host: hostname, scheme: "http"}
		end
		uri
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
		try do
			case HTTPoison.get(url) do
				{:ok, resp} -> resp.body
				{:error, _} -> nil
			end
		catch 
			:exit, code -> 
				IO.puts("ERROR, code #{inspect(code)}")
				nil
			# :exit, code - "Exited with code #{inspect code}"​
			# :throw, value - ​"throw called with #{inspect value}"​
			# what, value - "Caught #{inspect what} with #{inspect value}"​
		end
	end
end