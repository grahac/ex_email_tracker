defmodule ExEmailTracker.Tracker.PixelInjector do
  @moduledoc """
  Injects tracking pixel into email HTML.
  """

  @doc """
  Injects an invisible tracking pixel into the email's HTML body.
  """
  def inject(email, email_send_id) do
    pixel_html = build_pixel_html(email_send_id)
    
    Map.update(email, :html_body, nil, fn
      nil -> pixel_html
      html_body -> inject_into_html(html_body, pixel_html)
    end)
  end

  defp build_pixel_html(email_send_id) do
    base_url = ExEmailTracker.base_url()
    pixel_url = "#{base_url}/track/open/#{email_send_id}"
    
    ~s(<img src="#{pixel_url}" width="1" height="1" style="display:block;width:1px;height:1px;border:0;" alt="">)
  end

  defp inject_into_html(html_body, pixel_html) do
    cond do
      String.contains?(html_body, "</body>") ->
        String.replace(html_body, "</body>", "#{pixel_html}</body>")
        
      String.contains?(html_body, "</html>") ->
        String.replace(html_body, "</html>", "#{pixel_html}</html>")
        
      true ->
        html_body <> pixel_html
    end
  end
end