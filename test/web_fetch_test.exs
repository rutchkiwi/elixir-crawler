defmodule WebFetchTest do
	use ExUnit.Case

	test "fetch_url_test" do
		body = HttpFetcher.fetch("http://localhost:5000/text.html")
		assert body == ~s(<a href="http://b.com"></a>)
	end
end