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
	require Logger

	def start(fetcher, url_string, max_count \\ 20) do
		res = WorkHandler.start_and_crawl(max_count, url_string, fetcher)
		Logger.debug "res received"
		Logger.debug "slept"
		res
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
