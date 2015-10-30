defmodule CrawlingTest do
  use ExUnit.Case
  @moduletag timeout: 500

  def fake_fetcher_func(url) do
   pages = %{
    "http://a.com/a" =>
      ~s(<a href="http://a.com/b"></a>),
    "http://a.com/b" =>
      ~s(<h1> end of line! </h1>),
    "http://a.com/rel" =>
      ~s(<a href="/b"></a>),
    "http://a.com/loop" =>
      ~s(<a href="http://a.com/loop"></a>
        <a href="http://a.com/a"></a>)
    }
    pages[url]
  end

  test "empty" do
    res = Crawler.Main.start(&fake_fetcher_func/1, "http://non-existant.com")
    expected = HashSet.new
    assert expected == res
  end

  test "smoketest" do
  	res = Crawler.Main.start(&fake_fetcher_func/1, "http://a.com/b")
    expected = HashSet.new
    expected = Set.put(expected, "http://a.com/b")
  	assert expected == res
  end

  test "simple" do
  	res = Crawler.Main.start(&fake_fetcher_func/1, "http://a.com/a")
    expected = HashSet.new
    expected = Set.put(expected, "http://a.com/a")
    expected = Set.put(expected, "http://a.com/b")
    assert expected == res
  end

  test "loop" do
    res = Crawler.Main.start(&fake_fetcher_func/1, "http://a.com/loop")
    expected = HashSet.new
    expected = Set.put(expected, "http://a.com/loop")
    expected = Set.put(expected, "http://a.com/a")
    expected = Set.put(expected, "http://a.com/b")
    assert expected == res
  end

  test "relative" do
    res = Crawler.Main.start(&fake_fetcher_func/1, "http://a.com/rel")
    expected = HashSet.new
    expected = Set.put(expected, "http://a.com/rel")
    expected = Set.put(expected, "http://a.com/b")
    assert expected == res
  end

  def endless_fake_fetcher_func(_url) do
    "<a href=\"http://a.com/#{:random.uniform(10000000)}\"></a>"
  end

  test "stops after given number of pages found" do
    res = Crawler.Main.start(&endless_fake_fetcher_func/1, "http://a.com/a", 2)
    assert Set.size(res) == 2
  end
end
