defmodule ExEmailTracker.Tracker do
  @moduledoc """
  Core tracking functionality for emails.
  """
  alias ExEmailTracker.Schemas.EmailSend
  alias ExEmailTracker.Tracker.{LinkRewriter, PixelInjector}
  
  require Logger

  @doc """
  Tracks an email by injecting tracking pixel and rewriting links.
  """
  def track_email(email, opts) do
    cond do
      Keyword.get(opts, :skip_tracking, false) ->
        email
        
      should_suppress_email?(email, opts) ->
        # Return nil to indicate email should not be sent
        nil
        
      true ->
        opts = validate_opts!(opts)
        
        # Generate tracking ID
        email_send_id = Ecto.UUID.generate()
        
        # Store email send record
        {:ok, email_send} = create_email_send(email, email_send_id, opts)
        
        email
        |> inject_tracking_pixel(email_send_id)
        |> rewrite_links(email_send)
        |> add_unsubscribe_link(email_send)
        |> add_tracking_headers(email_send_id)
    end
  end
  
  defp should_suppress_email?(email, opts) do
    if Application.get_env(:ex_email_tracker, :check_unsubscribes, false) do
      %{to: [{_name, recipient_email}]} = email
      email_type = Keyword.fetch!(opts, :email_type)
      
      ExEmailTracker.Unsubscribe.unsubscribed?(recipient_email, email_type)
    else
      false
    end
  end

  defp validate_opts!(opts) do
    unless Keyword.has_key?(opts, :email_type) do
      raise ArgumentError, "email_type is required"
    end
    
    opts
  end

  defp create_email_send(email, email_send_id, opts) do
    %{to: [{_name, recipient_email}]} = email
    
    attrs = %{
      id: email_send_id,
      recipient_email: recipient_email,
      recipient_id: Keyword.get(opts, :recipient_id),
      email_type: to_string(Keyword.fetch!(opts, :email_type)),
      subject: email.subject,
      variant: opts[:variant] && to_string(opts[:variant]),
      metadata: Keyword.get(opts, :metadata, %{}),
      sent_at: DateTime.utc_now()
    }
    
    %EmailSend{}
    |> EmailSend.changeset(attrs)
    |> repo().insert()
  end

  defp inject_tracking_pixel(email, email_send_id) do
    if Application.get_env(:ex_email_tracker, :track_opens, true) do
      PixelInjector.inject(email, email_send_id)
    else
      email
    end
  end

  defp rewrite_links(email, email_send) do
    if Application.get_env(:ex_email_tracker, :track_clicks, true) do
      LinkRewriter.rewrite(email, email_send)
    else
      email
    end
  end

  defp add_unsubscribe_link(email, email_send) do
    if Application.get_env(:ex_email_tracker, :add_unsubscribe, true) do
      unsubscribe_url = build_unsubscribe_url(email_send)
      
      email
      |> Map.update(:headers, [{"List-Unsubscribe", "<#{unsubscribe_url}>"}], fn headers ->
        headers = normalize_headers(headers)
        [{"List-Unsubscribe", "<#{unsubscribe_url}>"} | headers]
      end)
    else
      email
    end
  end

  defp add_tracking_headers(email, email_send_id) do
    Map.update(email, :headers, [], fn headers ->
      headers = normalize_headers(headers)
      [{"X-Email-Track-ID", email_send_id} | headers]
    end)
  end

  defp normalize_headers(headers) when is_list(headers), do: headers
  defp normalize_headers(%{}), do: []
  defp normalize_headers(_), do: []

  defp build_unsubscribe_url(email_send) do
    base_url = ExEmailTracker.base_url()
    "#{base_url}/track/unsubscribe/#{email_send.id}"
  end

  defp repo do
    ExEmailTracker.repo()
  end
end