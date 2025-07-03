defmodule ExEmailTracker.Tracker.LinkRewriter do
  @moduledoc """
  Rewrites links in emails to track clicks.
  """
  alias ExEmailTracker.Schemas.EmailLink

  @link_regex ~r/<a\s+(?:[^>]*?\s+)?href=(["'])(.*?)\1(.*?)>(.*?)<\/a>/ims

  @doc """
  Rewrites all links in the email to track clicks.
  """
  def rewrite(email, email_send) do
    case email.html_body do
      nil -> 
        email
        
      html_body ->
        {rewritten_html, _} = 
          Regex.replace(@link_regex, html_body, fn full_match, quote, url, attrs, link_text ->
            rewrite_link(full_match, quote, url, attrs, link_text, email_send)
          end, global: true)
          |> then(&{&1, nil})
        
        Map.put(email, :html_body, rewritten_html)
    end
  end

  defp rewrite_link(full_match, quote, url, attrs, link_text, email_send) do
    # Skip if already a tracking URL or if it's a special URL
    if should_skip_url?(url) do
      full_match
    else
      # Store link in database
      {:ok, link} = create_email_link(email_send, url, link_text)
      
      # Build tracking URL
      tracking_url = build_tracking_url(email_send.id, link.id, url)
      
      # Reconstruct the link tag
      ~s(<a href=#{quote}#{tracking_url}#{quote}#{attrs}>#{link_text}</a>)
    end
  end

  defp should_skip_url?(url) do
    String.starts_with?(url, "#") ||
    String.starts_with?(url, "mailto:") ||
    String.starts_with?(url, "tel:") ||
    String.contains?(url, "/track/") ||
    url == ""
  end

  defp create_email_link(email_send, url, link_text) do
    attrs = %{
      email_send_id: email_send.id,
      original_url: url,
      link_text: clean_link_text(link_text)
    }
    
    %EmailLink{}
    |> EmailLink.changeset(attrs)
    |> repo().insert()
  end

  defp clean_link_text(text) do
    text
    |> String.replace(~r/<[^>]+>/, "")
    |> String.trim()
    |> String.slice(0, 255)
  end

  defp build_tracking_url(email_send_id, link_id, original_url) do
    base_url = ExEmailTracker.base_url()
    encoded_url = Base.url_encode64(original_url, padding: false)
    
    "#{base_url}/track/click/#{email_send_id}/#{link_id}?u=#{encoded_url}"
  end

  defp repo do
    ExEmailTracker.repo()
  end
end