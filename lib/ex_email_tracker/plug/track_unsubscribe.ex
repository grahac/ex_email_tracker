defmodule ExEmailTracker.Plug.TrackUnsubscribe do
  @moduledoc """
  Plug for handling email unsubscribe requests.
  """
  import Plug.Conn
  alias ExEmailTracker.Analytics.EventRecorder
  alias ExEmailTracker.Schemas.{EmailSend, EmailUnsubscribe}

  @behaviour Plug

  def init(opts), do: opts

  def call(%Plug.Conn{params: %{"email_send_id" => email_send_id}} = conn, _opts) do
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
    {:ok, _} = create_unsubscribe_record(email_send)

    # Call the callback if configured
    if callback = Application.get_env(:ex_email_tracker, :unsubscribe_callback) do
      callback.(%{
        email: email_send.recipient_email,
        email_type: email_send.email_type,
        recipient_id: email_send.recipient_id,
        metadata: email_send.metadata
      })
    end

    # Redirect to configured URL or default page
    redirect_url = build_redirect_url(email_send)
    
    conn
    |> put_resp_header("location", redirect_url)
    |> send_resp(302, "")
  end
  
  defp build_redirect_url(email_send) do
    case Application.get_env(:ex_email_tracker, :unsubscribe_redirect_url) do
      nil -> 
        # Default to a simple confirmation page if no URL configured
        "#{ExEmailTracker.base_url()}/unsubscribe/success"
        
      url when is_binary(url) ->
        # Simple string URL
        url
        
      url_fn when is_function(url_fn, 1) ->
        # Function that receives email_send and returns URL
        url_fn.(email_send)
    end
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