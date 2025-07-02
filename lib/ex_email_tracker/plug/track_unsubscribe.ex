defmodule ExEmailTracker.Plug.TrackUnsubscribe do
  @moduledoc """
  Plug for handling email unsubscribe requests.
  """
  import Plug.Conn
  alias ExEmailTracker.Analytics.EventRecorder
  alias ExEmailTracker.Schemas.{EmailSend, EmailUnsubscribe}

  @behaviour Plug

  def init(opts), do: opts

  def call(%Plug.Conn{path_info: ["track", "unsubscribe", email_send_id]} = conn, _opts) do
    case repo().get(EmailSend, email_send_id) do
      nil ->
        conn
        |> send_resp(404, "Email not found")
        
      email_send ->
        handle_unsubscribe(conn, email_send)
    end
  end

  def call(conn, _opts), do: conn

  defp handle_unsubscribe(conn, email_send) do
    # Record unsubscribe event
    EventRecorder.record_event(email_send.id, "unsubscribed", %{
      ip_address: get_client_ip(conn),
      user_agent: get_req_header(conn, "user-agent") |> List.first(),
      occurred_at: DateTime.utc_now()
    })

    # Create unsubscribe record
    create_unsubscribe_record(email_send)

    # Return confirmation page
    html_response = """
    <!DOCTYPE html>
    <html>
    <head>
      <title>Unsubscribed</title>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; text-align: center; }
        .success { color: #28a745; }
      </style>
    </head>
    <body>
      <h1 class="success">✓ Unsubscribed Successfully</h1>
      <p>You have been unsubscribed from <strong>#{email_send.email_type}</strong> emails.</p>
      <p>You will no longer receive emails of this type at <strong>#{email_send.recipient_email}</strong>.</p>
    </body>
    </html>
    """

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html_response)
  end

  defp create_unsubscribe_record(email_send) do
    attrs = %{
      recipient_email: email_send.recipient_email,
      email_type: email_send.email_type,
      unsubscribed_at: DateTime.utc_now(),
      reason: "manual_unsubscribe"
    }

    %EmailUnsubscribe{}
    |> EmailUnsubscribe.changeset(attrs)
    |> repo().insert(on_conflict: :nothing)
  end

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

  defp repo do
    ExEmailTracker.repo()
  end
end