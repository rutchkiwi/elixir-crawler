defmodule Crawler.CLI do
  def main([url]) do
    {:ok, resp} = HTTPoison.get(url)
    body = resp.body
    IO.puts body
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
				links = HtmlParser.get_links(body)
				crawl(fetcher_func, Set.put(visited, url), [rest | links])
			end
		end
	end
end

defmodule HtmlParser do
	def get_links(nil) do
		[]
	end

	def get_links(body) do
		Floki.attribute(body, "a", "href")
	end
end