defmodule ResultsTest do
  use ExUnit.Case
  @moduletag timeout: 500

  setup do
    Results.start_link()
    :ok
  end

  test "empty" do
    assert Results.get_all_results() == HashSet.new
  end

  test "single" do
    Results.report_visited_uri(URI.parse("www.test.com"))
    expected = HashSet.new
    expected = Set.put(expected, "www.test.com")
    assert Results.get_all_results() == expected
  end
end