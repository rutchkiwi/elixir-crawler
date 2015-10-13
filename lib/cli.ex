defmodule Crawler.CLI do
  def main([url]) do
    {:ok, resp} = HTTPoison.get(url)
    body = resp.body
    IO.puts body
  end
end

defmodule Crawler.Main do
	def crawl(fetcher_func, url) do
		IO.puts "============="
		body = fetcher_func.(url)
		links = HtmlParser.get_links(body)
		IO.inspect(links)
		rest = Enum.map(links, &crawl(fetcher_func, &1))
		to_return = [url | rest]
		IO.puts("to return: [#{url} | #{inspect(rest)} ]")
		List.flatten(to_return) #TODO: wierd
	end
end


defmodule HtmlParser do
	def get_links(body) do
		Floki.attribute(body, "a", "href")
	end
end
