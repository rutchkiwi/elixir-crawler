defmodule CrawlingTest do
  use ExUnit.Case
  @moduletag timeout: 500

  def fake_fetcher_func(url) do
   pages = %{
    "http://a.com" =>
      ~s(<a href="http://b.com"></a>),
    "http://b.com" =>
      ~s(<h1> end of line! </h1>),
    "http://loop.com" =>
      ~s(<a href="http://loop.com"></a>
        <a href="http://a.com"></a>)
    }
    pages[url]
  end


  test "smoketest" do
  	res = Crawler.Main.crawl(&fake_fetcher_func/1, "http://b.com")
  	assert ["http://b.com"] == res
  end

  test "simple" do
  	res = Crawler.Main.crawl(&fake_fetcher_func/1, "http://a.com")
  	assert ["http://a.com", "http://b.com"] == res
  end

  test "loop" do
    res = Crawler.Main.crawl(&fake_fetcher_func/1, "http://loop.com")
    assert ["http://loop.com", "http://a.com", "http://b.com"] == res
  end
end
