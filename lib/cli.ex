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
	def start(fetcher, url) do
		crawl(fetcher, HashSet.new, [url])
	end

	def crawl(_, visited, []) do
		visited
	end

	def crawl(fetcher_func, visited, queue) do
		[url | rest] = queue
		if Set.member?(visited, url) do
			crawl(fetcher_func, visited, rest)	
		else
			body = fetcher_func.(url)
			if body == nil do
				crawl(fetcher_func, visited, rest)
			else
				IO.inspect(body)	
				links = HtmlParser.get_links(body)
				crawl(fetcher_func, Set.put(visited, url), rest ++ links)
			end
		end
	end
end

defmodule HtmlParser do
	def get_links(nil) do
		[]
	end

	def get_links(body) do
		IO.puts "parsing body #{body}"
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