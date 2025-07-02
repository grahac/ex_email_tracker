defmodule ExEmailTracker.Analytics do
  @moduledoc """
  Analytics queries for email tracking data.
  """
  import Ecto.Query
  alias ExEmailTracker.Schemas.{EmailSend, EmailEvent}

  @doc """
  Gets summary statistics for emails.
  """
  def get_summary_stats(opts \\ []) do
    # Single optimized query using conditional aggregation
    stats = 
      from es in EmailSend,
      left_join: e in EmailEvent, on: e.email_send_id == es.id,
      where: ^filter_conditions(opts),
      select: %{
        sent: count(es.id),
        opened: count(fragment("DISTINCT CASE WHEN ? = 'opened' THEN ? END", e.event_type, e.email_send_id)),
        clicked: count(fragment("DISTINCT CASE WHEN ? = 'clicked' THEN ? END", e.event_type, e.email_send_id)),
        bounced: count(fragment("DISTINCT CASE WHEN ? = 'bounced' THEN ? END", e.event_type, e.email_send_id))
      }
    
    result = repo().one(stats)

    %{
      sent: result.sent,
      opened: result.opened,
      clicked: result.clicked,
      bounced: result.bounced,
      open_rate: calculate_rate(result.opened, result.sent),
      click_rate: calculate_rate(result.clicked, result.sent),
      bounce_rate: calculate_rate(result.bounced, result.sent)
    }
  end

  @doc """
  Gets email performance by type.
  """
  def get_performance_by_type(opts \\ []) do
    # Optimized query using conditional aggregation
    query = 
      from es in EmailSend,
      left_join: e in EmailEvent, on: e.email_send_id == es.id,
      where: ^filter_conditions(opts),
      group_by: es.email_type,
      select: %{
        email_type: es.email_type,
        sent: count(es.id),
        opened: count(fragment("DISTINCT CASE WHEN ? = 'opened' THEN ? END", e.event_type, e.email_send_id)),
        clicked: count(fragment("DISTINCT CASE WHEN ? = 'clicked' THEN ? END", e.event_type, e.email_send_id))
      }
    
    results = repo().all(query)
    
    Enum.map(results, fn result ->
      Map.merge(result, %{
        open_rate: calculate_rate(result.opened, result.sent),
        click_rate: calculate_rate(result.clicked, result.sent)
      })
    end)
  end

  @doc """
  Gets recent email activity.
  """
  def get_recent_activity(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    # Cap limit to prevent performance issues
    limit = min(limit, 1000)
    
    # Build the filters manually to ensure correct binding
    filter_query = build_recent_activity_filters(opts)
    
    from(e in EmailEvent,
      join: es in EmailSend, on: e.email_send_id == es.id,
      where: ^filter_query,
      order_by: [desc: e.occurred_at],
      limit: ^limit,
      select: %{
        id: e.id,
        event_type: e.event_type,
        occurred_at: e.occurred_at,
        email_type: es.email_type,
        recipient_email: es.recipient_email,
        click_url: e.click_url
      }
    )
    |> repo().all()
  end

  @doc """
  Gets email timeline data for charts.
  """
  def get_timeline_data(opts \\ []) do
    group_by = Keyword.get(opts, :group_by, :day)
    
    date_trunc = case group_by do
      :hour -> "hour"
      :day -> "day"
      :week -> "week"
      :month -> "month"
    end
    
    from(es in base_query(opts),
      left_join: opened in EmailEvent,
        on: opened.email_send_id == es.id and opened.event_type == "opened",
      left_join: clicked in EmailEvent,
        on: clicked.email_send_id == es.id and clicked.event_type == "clicked",
      group_by: fragment("date_trunc(?, ?)", ^date_trunc, es.sent_at),
      order_by: fragment("date_trunc(?, ?)", ^date_trunc, es.sent_at),
      select: %{
        date: fragment("date_trunc(?, ?)", ^date_trunc, es.sent_at),
        sent: count(es.id),
        opened: count(fragment("DISTINCT ?", opened.email_send_id)),
        clicked: count(fragment("DISTINCT ?", clicked.email_send_id))
      }
    )
    |> repo().all()
  end

  @doc """
  Gets individual email details.
  """
  def get_email_details(email_send_id) do
    email_send = repo().get(EmailSend, email_send_id)
    
    if email_send do
      events = 
        from(e in EmailEvent,
          where: e.email_send_id == ^email_send_id,
          order_by: [desc: e.occurred_at]
        )
        |> repo().all()
      
      %{
        email_send: email_send,
        events: events,
        stats: calculate_email_stats(events)
      }
    else
      nil
    end
  end

  defp base_query(opts) do
    from(es in EmailSend, where: ^filter_conditions(opts))
  end


  defp filter_conditions(opts) do
    conditions = true
    
    conditions = 
      if start_date = opts[:start_date] do
        dynamic([es], ^conditions and es.sent_at >= ^start_date)
      else
        # Default to last 90 days to prevent full table scans
        default_start = DateTime.add(DateTime.utc_now(), -90, :day)
        dynamic([es], ^conditions and es.sent_at >= ^default_start)
      end
    
    conditions = 
      if end_date = opts[:end_date] do
        dynamic([es], ^conditions and es.sent_at <= ^end_date)
      else
        conditions
      end
    
    conditions = 
      if email_type = opts[:email_type] do
        dynamic([es], ^conditions and es.email_type == ^email_type)
      else
        conditions
      end
    
    conditions = 
      if recipient_id = opts[:recipient_id] do
        dynamic([es], ^conditions and es.recipient_id == ^recipient_id)
      else
        conditions
      end
    
    conditions = 
      if organization_id = opts[:organization_id] do
        dynamic([es], ^conditions and fragment("?->>'organization_id' = ?", es.metadata, ^to_string(organization_id)))
      else
        conditions
      end
    
    conditions
  end

  defp build_recent_activity_filters(opts) do
    conditions = true
    
    conditions = 
      if start_date = opts[:start_date] do
        dynamic([event, email_send], ^conditions and email_send.sent_at >= ^start_date)
      else
        # Default to last 90 days to prevent full table scans
        default_start = DateTime.add(DateTime.utc_now(), -90, :day)
        dynamic([event, email_send], ^conditions and email_send.sent_at >= ^default_start)
      end
    
    conditions = 
      if end_date = opts[:end_date] do
        dynamic([event, email_send], ^conditions and email_send.sent_at <= ^end_date)
      else
        conditions
      end
    
    conditions = 
      if email_type = opts[:email_type] do
        dynamic([event, email_send], ^conditions and email_send.email_type == ^email_type)
      else
        conditions
      end
    
    conditions = 
      if recipient_id = opts[:recipient_id] do
        dynamic([event, email_send], ^conditions and email_send.recipient_id == ^recipient_id)
      else
        conditions
      end
    
    conditions = 
      if organization_id = opts[:organization_id] do
        dynamic([event, email_send], ^conditions and fragment("?->>'organization_id' = ?", email_send.metadata, ^to_string(organization_id)))
      else
        conditions
      end
    
    conditions
  end


  defp calculate_rate(numerator, denominator) when denominator > 0 do
    Float.round(numerator / denominator * 100, 2)
  end
  defp calculate_rate(_, _), do: 0.0

  defp calculate_email_stats(events) do
    opened = Enum.any?(events, &(&1.event_type == "opened"))
    clicked = Enum.any?(events, &(&1.event_type == "clicked"))
    bounced = Enum.any?(events, &(&1.event_type == "bounced"))
    
    %{
      opened: opened,
      clicked: clicked,
      bounced: bounced,
      event_count: length(events)
    }
  end

  defp repo do
    ExEmailTracker.repo()
  end
end