defmodule ErrorsInCrawlingTest do
  use ExUnit.Case
  @moduletag timeout: 500

  def crashy_fetcher("http://a.com/a"), do: {:ok, ~s(<a href="http://a.com/b"></a> <a href="http://a.com/c"></a>)}
  def crashy_fetcher("http://a.com/b"), do: raise "boom"
  def crashy_fetcher("http://a.com/c"), do: {:ok, ~s(end of line!)}
   
  test "persistant error on page" do
    res = Crawler.Main.start(&crashy_fetcher/1, "http://a.com/a")
    expected = HashSet.new
    expected = Set.put(expected, "http://a.com/a")
    expected = Set.put(expected, "http://a.com/c")
    assert expected == res  
  end

# TODO errors in fetch

  def recovering_after_3_tries("http://a.com/a"), do: {:ok, ~s(<a href="http://a.com/b"></a> <a href="http://a.com/c"></a>)}
  def recovering_after_3_tries("http://a.com/b"), do: {:ok, ~s(end of line!)}
  def recovering_after_3_tries("http://a.com/c") do
    case Counter.increment(:test_counter) do
      1 -> raise ">_<"
      2 -> raise "o_o"
      3 -> raise "O_O"
      _ -> {:ok, ~s(back up!)}
    end
  end
   
  test "one recoverable error on page" do
    Counter.start_link() |>
      Process.register(:test_counter)

    res = Crawler.Main.start(&recovering_after_3_tries/1, "http://a.com/a")
    expected = HashSet.new
    expected = Set.put(expected, "http://a.com/a")
    expected = Set.put(expected, "http://a.com/b")
    expected = Set.put(expected, "http://a.com/c")
    assert expected == res  
  end
end

# TODO: add test for well behaved http errors
# TODO errors in fetcher handling tests
# TODO slow fetchers