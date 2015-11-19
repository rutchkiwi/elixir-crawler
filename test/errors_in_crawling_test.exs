defmodule ErrorsInCrawlingTest do
  use ExUnit.Case
  @moduletag timeout: 500
  
  setup do
    # so that we can make errors recover after a certain number of tries
    Counter.start_link() |>
      Process.register(:test_counter)
    :ok
  end

   
  @tag capture_log: true
  test "persistant error on page" do
    crashy_fetcher = fn 
      "http://a.com/a" -> {:ok, ~s(<a href="http://a.com/b"></a> <a href="http://a.com/c"></a>)}
      "http://a.com/b" -> raise "boom"
      "http://a.com/c" -> {:ok, ~s(end of line!)}
    end
    
    res = Crawler.Main.start(crashy_fetcher, "http://a.com/a")
    expected = HashSet.new
    expected = Set.put(expected, "http://a.com/a")
    expected = Set.put(expected, "http://a.com/c")
    assert expected == res  
  end

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
   
  @tag capture_log: true
  test "one recoverable error on page" do
    res = Crawler.Main.start(&recovering_after_3_tries/1, "http://a.com/a")
    expected = HashSet.new
    expected = Set.put(expected, "http://a.com/a")
    expected = Set.put(expected, "http://a.com/b")
    expected = Set.put(expected, "http://a.com/c")
    assert expected == res  
  end

  test "well behaved errors" do
    fetcher = fn
      "http://a.com/a" -> {:ok, ~s(<a href="http://a.com/b"></a>)}
      "http://a.com/b" -> case Counter.increment(:test_counter) do
                            1 -> :error
                            2 -> {:ok, "end of line!"}
                          end
      end

    res = Crawler.Main.start(fetcher, "http://a.com/a")
    expected = HashSet.new
    expected = Set.put(expected, "http://a.com/a")
    expected = Set.put(expected, "http://a.com/b")
    assert expected == res
  end
end

# TODO slow fetchers