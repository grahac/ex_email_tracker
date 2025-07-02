defmodule ExEmailTracker.Plug.TrackClick do
  @moduledoc """
  Plug for handling email click tracking and redirects.
  """
  import Plug.Conn
  alias ExEmailTracker.Analytics.EventRecorder

  @behaviour Plug

  def init(opts), do: opts

  def call(%Plug.Conn{path_info: ["track", "click", email_send_id, link_id]} = conn, _opts) do
    # Get the original URL
    original_url = case conn.params["u"] do
      nil -> "/"
      encoded_url ->
        case Base.url_decode64(encoded_url, padding: false) do
          {:ok, url} -> url
          :error -> "/"
        end
    end

    # Record the click event
    EventRecorder.record_event(email_send_id, "clicked", %{
      ip_address: get_client_ip(conn),
      user_agent: get_req_header(conn, "user-agent") |> List.first(),
      click_url: original_url,
      occurred_at: DateTime.utc_now(),
      metadata: %{link_id: link_id}
    })

    # Redirect to original URL
    conn
    |> put_resp_header("location", original_url)
    |> send_resp(302, "")
  end

  def call(conn, _opts), do: conn

  defp get_client_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [forwarded_for] ->
        forwarded_for
        |> String.split(",")
        |> List.first()
        |> String.trim()
        
      [] ->
        conn.remote_ip
        |> :inet.ntoa()
        |> to_string()
    end
  end
end