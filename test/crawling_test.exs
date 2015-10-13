defmodule CrawlingTest do
  use ExUnit.Case

  def fake_fetcher_func("http://a.com") do
  	~s(<a href="http://b.com"></a>)
  end
  def fake_fetcher_func("http://b.com") do
  	~s(<h1> end of line! </h1>)
  end

  # test "smoketest" do
  # 	res = Crawler.Main.crawl(&fake_fetcher_func/1, "http://b.com")
  # 	assert ["http://b.com"] == res
  # end

  test "simple" do
  	res = Crawler.Main.crawl(&fake_fetcher_func/1, "http://a.com")
  	assert ["http://a.com", "http://b.com"] == res
  end
end
