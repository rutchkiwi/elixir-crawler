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

  test "empty" do
    res = Crawler.Main.start(&fake_fetcher_func/1, "http://non-existant.com")
    expected = HashSet.new
    assert expected == res
  end

  test "smoketest" do
  	res = Crawler.Main.start(&fake_fetcher_func/1, "http://b.com")
    expected = HashSet.new
    expected = Set.put(expected, "http://b.com")
  	assert expected == res
  end

  test "simple" do
  	res = Crawler.Main.start(&fake_fetcher_func/1, "http://a.com")
    expected = HashSet.new
    expected = Set.put(expected, "http://a.com")
    expected = Set.put(expected, "http://b.com")
    assert expected == res
  end

  test "loop" do
    res = Crawler.Main.start(&fake_fetcher_func/1, "http://loop.com")
    expected = HashSet.new
    expected = Set.put(expected, "http://loop.com")
    expected = Set.put(expected, "http://a.com")
    expected = Set.put(expected, "http://b.com")
    assert expected == res
  end
end
