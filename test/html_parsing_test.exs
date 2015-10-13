defmodule HtmlParsingTest do
  use ExUnit.Case

  test "super simple html" do
  	html = ~s(<a href="http://www.w3schools.com">Visit W3Schools</a>)
    assert HtmlParser.get_links(html) == ["http://www.w3schools.com"]
  end

  test "another super simple html" do
  	html = ~s(<a href="http://www.dn.se"></a>)
    assert HtmlParser.get_links(html) == ["http://www.dn.se"]
  end

   test "two links" do
  	html = ~s(
  		<h1><a href="http://www.dn.se">First link</a></h1>
  		<a href="http://www.potato.net"></a>)
    assert HtmlParser.get_links(html) == 
    	["http://www.dn.se", "http://www.potato.net"]
  end
end
