defmodule ExEmailTracker.Tracker.LinkRewriterTest do
  use ExUnit.Case
  
  # Test the regex pattern directly without database dependencies
  @link_regex ~r/<a\s+(?:[^>]*?\s+)?href=(["'])(.*?)\1(.*?)>(.*?)<\/a>/ims

  describe "regex pattern matching" do
    test "matches single link on one line" do
      html = ~s(<p>Check out <a href="https://example.com">our site</a>!</p>)
      
      matches = Regex.scan(@link_regex, html)
      assert length(matches) == 1
      
      [match] = matches
      [_full_match, quote, url, attrs, link_text] = match
      
      assert quote == "\""
      assert url == "https://example.com"
      assert attrs == ""
      assert link_text == "our site"
    end

    test "matches single link spanning multiple lines" do
      html = """
      <div style="padding: 24px; text-align: center; background-color: #f9fafb;">
        <a href="https://example.com/analysis/123" style="display: inline-block; background-color: #4f46e5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: 500; font-size: 14px;">
          View Full Analysis →
        </a>
      </div>
      """
      
      matches = Regex.scan(@link_regex, html)
      assert length(matches) == 1
      
      [match] = matches
      [_full_match, quote, url, attrs, link_text] = match
      
      assert quote == "\""
      assert url == "https://example.com/analysis/123"
      assert attrs =~ "style="
      assert link_text =~ "View Full Analysis →"
    end

    test "matches multiple links on same line" do
      html = ~s(<p><a href="https://example.com">First</a> and <a href="https://google.com">Second</a></p>)
      
      matches = Regex.scan(@link_regex, html)
      assert length(matches) == 2
      
      [first_match, second_match] = matches
      
      # First link
      [_full_match, quote, url, _attrs, link_text] = first_match
      assert quote == "\""
      assert url == "https://example.com"
      assert link_text == "First"
      
      # Second link
      [_full_match, quote, url, _attrs, link_text] = second_match
      assert quote == "\""
      assert url == "https://google.com"
      assert link_text == "Second"
    end

    test "matches multiple links on different lines" do
      html = """
      <div>
        <p><a href="https://example.com">First Link</a></p>
        <p><a href="https://google.com">Second Link</a></p>
        <p><a href="https://github.com">Third Link</a></p>
      </div>
      """
      
      matches = Regex.scan(@link_regex, html)
      assert length(matches) == 3
      
      urls = Enum.map(matches, fn [_full, _quote, url, _attrs, _text] -> url end)
      link_texts = Enum.map(matches, fn [_full, _quote, _url, _attrs, text] -> text end)
      
      assert "https://example.com" in urls
      assert "https://google.com" in urls
      assert "https://github.com" in urls
      
      assert "First Link" in link_texts
      assert "Second Link" in link_texts
      assert "Third Link" in link_texts
    end

    test "handles mixed single-line and multi-line links" do
      html = """
      <div>
        <p><a href="https://example.com">Single line link</a></p>
        <div style="padding: 24px;">
          <a href="https://multiline.com" 
             style="color: blue;">
            Multi-line link
          </a>
        </div>
      </div>
      """
      
      matches = Regex.scan(@link_regex, html)
      assert length(matches) == 2
      
      urls = Enum.map(matches, fn [_full, _quote, url, _attrs, _text] -> url end)
      assert "https://example.com" in urls
      assert "https://multiline.com" in urls
    end

    test "handles links with complex attributes" do
      html = """
      <a href="https://example.com" 
         class="btn btn-primary" 
         data-toggle="modal" 
         style="color: white; background: blue;"
         target="_blank"
         rel="noopener">
        Complex Link
      </a>
      """
      
      matches = Regex.scan(@link_regex, html)
      assert length(matches) == 1
      
      [match] = matches
      [_full_match, quote, url, attrs, link_text] = match
      
      assert quote == "\""
      assert url == "https://example.com"
      assert attrs =~ "class=\"btn btn-primary\""
      assert attrs =~ "data-toggle=\"modal\""
      assert attrs =~ "target=\"_blank\""
      assert attrs =~ "rel=\"noopener\""
      assert link_text =~ "Complex Link"
    end

    test "handles links with both single and double quotes" do
      html = """
      <div>
        <a href="https://example.com">Double quotes</a>
        <a href='https://google.com'>Single quotes</a>
      </div>
      """
      
      matches = Regex.scan(@link_regex, html)
      assert length(matches) == 2
      
      # Check that both quote types are captured correctly
      quotes = Enum.map(matches, fn [_full, quote, _url, _attrs, _text] -> quote end)
      assert "\"" in quotes
      assert "'" in quotes
    end

    test "handles links with HTML entities in text" do
      html = ~s(<p><a href="https://example.com">Read more &rarr;</a></p>)
      
      matches = Regex.scan(@link_regex, html)
      assert length(matches) == 1
      
      [match] = matches
      [_full_match, _quote, url, _attrs, link_text] = match
      
      assert url == "https://example.com"
      assert link_text == "Read more &rarr;"
    end

    test "handles nested elements in link text" do
      html = ~s(<p><a href="https://example.com"><strong>Bold</strong> text</a></p>)
      
      matches = Regex.scan(@link_regex, html)
      assert length(matches) == 1
      
      [match] = matches
      [_full_match, _quote, url, _attrs, link_text] = match
      
      assert url == "https://example.com"
      assert link_text == "<strong>Bold</strong> text"
    end

    test "handles very long URLs" do
      long_url = "https://example.com/" <> String.duplicate("a", 1000)
      html = ~s(<p><a href="#{long_url}">Long URL</a></p>)
      
      matches = Regex.scan(@link_regex, html)
      assert length(matches) == 1
      
      [match] = matches
      [_full_match, _quote, url, _attrs, link_text] = match
      
      assert url == long_url
      assert link_text == "Long URL"
    end

    test "does not match malformed HTML" do
      html = ~s(<p><a href="https://example.com">Unclosed link</p>)
      
      matches = Regex.scan(@link_regex, html)
      assert length(matches) == 0
    end

    test "does not match incomplete links" do
      html = ~s(<p><a>No href</a></p>)
      
      matches = Regex.scan(@link_regex, html)
      assert length(matches) == 0
    end

    test "handles whitespace variations in attributes" do
      html = ~s(<a href="https://example.com">Link</a>)
      
      matches = Regex.scan(@link_regex, html)
      assert length(matches) == 1
      
      [match] = matches
      [_full_match, _quote, url, _attrs, link_text] = match
      
      assert url == "https://example.com"
      assert link_text == "Link"
    end
  end

  describe "regex correctness for specific edge cases" do
    test "correctly matches the first closing tag for multiple links" do
      # This is the key test - ensures regex doesn't match across links
      html = ~s(<p><a href="https://first.com">First</a> and <a href="https://second.com">Second</a></p>)
      
      matches = Regex.scan(@link_regex, html)
      assert length(matches) == 2
      
      [first_match, second_match] = matches
      
      # First link should only contain "First", not "First</a> and <a href="https://second.com">Second"
      [_full_match, _quote, url, _attrs, link_text] = first_match
      assert url == "https://first.com"
      assert link_text == "First"
      refute link_text =~ "Second"
      
      # Second link should only contain "Second"
      [_full_match, _quote, url, _attrs, link_text] = second_match
      assert url == "https://second.com"
      assert link_text == "Second"
      refute link_text =~ "First"
    end

    test "handles the original problematic case from the issue" do
      # This is the exact HTML structure from the user's issue
      html = """
      <div style="padding: 24px; text-align: center; background-color: #f9fafb;">
        <a href="https://example.com/analysis/123" style="display: inline-block; background-color: #4f46e5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: 500; font-size: 14px;">
          View Full Analysis →
        </a>
      </div>
      """
      
      matches = Regex.scan(@link_regex, html)
      assert length(matches) == 1
      
      [match] = matches
      [_full_match, quote, url, attrs, link_text] = match
      
      assert quote == "\""
      assert url == "https://example.com/analysis/123"
      assert attrs =~ "style="
      assert attrs =~ "display: inline-block"
      assert attrs =~ "background-color: #4f46e5"
      assert link_text =~ "View Full Analysis →"
    end

    test "regex is non-greedy and stops at first closing tag" do
      html = ~s(<a href="https://example.com">Link <span>with</span> nested</a> <a href="https://other.com">Other</a>)
      
      matches = Regex.scan(@link_regex, html)
      assert length(matches) == 2
      
      [first_match, second_match] = matches
      
      # First match should stop at first </a>
      [_full_match, _quote, url, _attrs, link_text] = first_match
      assert url == "https://example.com"
      assert link_text == "Link <span>with</span> nested"
      refute link_text =~ "Other"
      
      # Second match should be separate
      [_full_match, _quote, url, _attrs, link_text] = second_match
      assert url == "https://other.com"
      assert link_text == "Other"
    end
  end
end