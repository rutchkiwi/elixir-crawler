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
		crawl(fetcher, url)
	end

	def crawl(fetcher_func, url) do
		body = fetcher_func.(url)
		links = HtmlParser.get_links(body)
		rest = Enum.map(links, &crawl(fetcher_func, &1))
		[url | List.flatten(rest)]
	end
end

defmodule HtmlParser do
	def get_links(body) do
		Floki.attribute(body, "a", "href")
	end
end