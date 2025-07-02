defmodule ExEmailTracker.Plug.TrackOpen do
  @moduledoc """
  Plug for handling email open tracking via transparent pixel.
  """
  import Plug.Conn
  alias ExEmailTracker.Analytics.EventRecorder

  @behaviour Plug

  def init(opts), do: opts

  def call(%Plug.Conn{params: %{"email_send_id" => email_send_id}} = conn, _opts) do
    # Record the open event
    EventRecorder.record_event(email_send_id, "opened", %{
      ip_address: get_client_ip(conn),
      user_agent: get_req_header(conn, "user-agent") |> List.first(),
      occurred_at: DateTime.utc_now()
    })

    # Return 1x1 transparent pixel
    conn
    |> put_resp_content_type("image/png")
    |> put_resp_header("cache-control", "no-cache, no-store, must-revalidate")
    |> put_resp_header("pragma", "no-cache")
    |> put_resp_header("expires", "0")
    |> send_resp(200, transparent_pixel())
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

  defp transparent_pixel do
    # 1x1 transparent PNG pixel
    <<137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 11, 73, 68, 65, 84, 120, 218, 99, 248, 15, 0, 1, 1, 1, 0, 24, 221, 141, 219, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130>>
  end
end