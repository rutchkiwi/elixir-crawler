defmodule ErrorsInCrawlingTest do
  use ExUnit.Case
  require Counter
  @moduletag timeout: 500
   
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

  @tag capture_log: true
  test "one recoverable error on page" do
    counter_pid = Counter.start_link()
    recovering_after_3_tries = fn "http://a.com/a" -> {:ok, ~s(<a href="http://a.com/b"></a> <a href="http://a.com/c"></a>)}
                 "http://a.com/b" -> {:ok, ~s(end of line!)}
                 "http://a.com/c" -> case Counter.increment(counter_pid) do
                                        1 -> raise ">_<"
                                        2 -> raise "o_o"
                                        3 -> raise "O_O"
                                        _ -> {:ok, ~s(back up!)}
                                      end
    end
     
    res = Crawler.Main.start(recovering_after_3_tries, "http://a.com/a")
    expected = HashSet.new
    expected = Set.put(expected, "http://a.com/a")
    expected = Set.put(expected, "http://a.com/b")
    expected = Set.put(expected, "http://a.com/c")
    assert expected == res  
  end

  test "well behaved errors" do
    counter_pid = Counter.start_link()

    fetcher = fn
      "http://a.com/a" -> {:ok, ~s(<a href="http://a.com/b"></a>)}
      "http://a.com/b" -> case Counter.increment(counter_pid) do
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