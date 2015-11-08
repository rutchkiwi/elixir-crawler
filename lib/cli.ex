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

defmodule Crawler.Main do
	def start(fetcher, url_string, max_count \\ 20) do
		WorkerSupervisor.start_link(fetcher, url_string, max_count, self())
		WorkHandler.crawl(url_string)
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
				# todo: let this crash
				IO.puts("ERROR, code #{inspect(code)}")
				nil
			# :exit, code - "Exited with code #{inspect code}"​
			# :throw, value - ​"throw called with #{inspect value}"​
			# what, value - "Caught #{inspect what} with #{inspect value}"​
		end
	end
end