defmodule HttpFetcher do
	def fetch(url) do
		{:ok, resp} = HTTPoison.get(url)
		{:ok, resp.body}
	end
end