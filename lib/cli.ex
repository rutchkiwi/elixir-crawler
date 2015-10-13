defmodule Crawler.CLI do
  def main([url]) do
    {:ok, resp} = HTTPoison.get(url)
    body = resp.body


  end
end

defmodule HtmlParser do
	def get_links(body) do
		["http://www.w3schools.com"]
	end
end
