defmodule ExEmailTracker.Analytics.EventRecorder do
  @moduledoc """
  Records email events for analytics.
  """
  alias ExEmailTracker.Schemas.EmailEvent
  require Logger

  @doc """
  Records an email event.
  """
  def record_event(email_send_id, event_type, attrs \\ %{}) do
    attrs = Map.merge(attrs, %{
      email_send_id: email_send_id,
      event_type: event_type,
      occurred_at: attrs[:occurred_at] || DateTime.utc_now()
    })

    %EmailEvent{}
    |> EmailEvent.changeset(attrs)
    |> repo().insert()
    |> case do
      {:ok, event} -> 
        broadcast_event(event)
        {:ok, event}
        
      {:error, changeset} ->
        Logger.warning("Failed to record email event: #{inspect(changeset.errors)}")
        {:error, changeset}
    end
  end

  defp broadcast_event(event) do
    # Only broadcast if PubSub is configured
    if pubsub = Application.get_env(:ex_email_tracker, :pubsub) do
      Phoenix.PubSub.broadcast(
        pubsub,
        "email_events",
        {:email_event, event}
      )
    end
  end

  defp repo do
    ExEmailTracker.repo()
  end
end