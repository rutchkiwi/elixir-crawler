# TODO: run over multiple machines

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
		WorkerSupervisor.start_link(fetcher, host)
		Queue.enqueue(uri)
		receive do
			:done -> :done
		end
		# crawl(fetcher, [uri], host, 0, max_count)
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
		# IO.puts "fetching url #{inspect(url)}"
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