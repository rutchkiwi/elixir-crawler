defmodule ResultsTest do
  use ExUnit.Case
  @moduletag timeout: 500

  test "empty" do
    pid = Results.start_link()

    assert Results.get_all_results(pid) == HashSet.new
  end

  test "single" do
    pid = Results.start_link()

    Results.report_visited_uri(pid, URI.parse("www.test.com"))
   
    expected = HashSet.new
    expected = Set.put(expected, "www.test.com")
    assert Results.get_all_results(pid) == expected
  end

  test "multiple" do
    pid = Results.start_link()

    Results.report_visited_uri(pid, URI.parse("www.test1.com"))
    Results.report_visited_uri(pid, URI.parse("www.test2.com"))
   
    expected = HashSet.new
    expected = Set.put(expected, "www.test1.com")
    expected = Set.put(expected, "www.test2.com")
    assert Results.get_all_results(pid) == expected
  end

end