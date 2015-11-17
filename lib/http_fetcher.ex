defmodule HttpFetcher do
	def fetch(url) do
		{:ok, resp} = HTTPoison.get(url)
		resp.body
	end
end