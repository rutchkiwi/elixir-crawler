defmodule ErrorsInCrawlingTest do
  use ExUnit.Case
  @moduletag timeout: 500

  def crashy_fetcher("http://a.com/a"), do: ~s(<a href="http://a.com/b"></a> <a href="http://a.com/c"></a>)
  def crashy_fetcher("http://a.com/b"), do: raise "boom"
  def crashy_fetcher("http://a.com/c"), do: ~s(end of line!)
   
  test "persistant error on page" do
    res = Crawler.Main.start(&crashy_fetcher/1, "http://a.com/a")
    expected = HashSet.new
    expected = Set.put(expected, "http://a.com/a")
    expected = Set.put(expected, "http://a.com/c")
    assert expected == res  
  end

# TODO errors in fetch

  def single_crash_fetcher("http://a.com/a"), do: ~s(<a href="http://a.com/b"></a> <a href="http://a.com/c"></a>)
  def single_crash_fetcher("http://a.com/b"), do: ~s(end of line!)
  def single_crash_fetcher("http://a.com/c") do
    case Counter.increment(:test_counter) do
      0 -> raise "boom"
      _ -> ~s(end of line!)
    end
  end
   
  test "one time error on page" do
    Counter.start_link() |>
      Process.register(:test_counter)

    res = Crawler.Main.start(&single_crash_fetcher/1, "http://a.com/a")
    expected = HashSet.new
    expected = Set.put(expected, "http://a.com/a")
    expected = Set.put(expected, "http://a.com/b")
    expected = Set.put(expected, "http://a.com/c")
    assert expected == res  
  end
end
# TODO errors in fetcher handling tests
# TODO slow fetchers