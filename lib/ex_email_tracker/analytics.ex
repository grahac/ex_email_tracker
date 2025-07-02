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
    # Get date range for filtering
    {start_date, end_date} = get_date_range(opts)
    
    # Count total sent emails
    sent_query = from es in EmailSend,
      where: es.sent_at >= ^start_date and es.sent_at <= ^end_date,
      select: count(es.id)
    
    sent_count = repo().one(sent_query)
    
    # Count events by type
    events_query = from ev in EmailEvent,
      join: es in EmailSend, on: ev.email_send_id == es.id,
      where: es.sent_at >= ^start_date and es.sent_at <= ^end_date,
      group_by: ev.event_type,
      select: {ev.event_type, count(fragment("DISTINCT ?", ev.email_send_id))}
    
    event_counts = repo().all(events_query) |> Enum.into(%{})
    
    opened_count = Map.get(event_counts, "opened", 0)
    clicked_count = Map.get(event_counts, "clicked", 0)
    bounced_count = Map.get(event_counts, "bounced", 0)
    
    %{
      sent: sent_count,
      opened: opened_count,  
      clicked: clicked_count,
      bounced: bounced_count,
      open_rate: calculate_rate(opened_count, sent_count),
      click_rate: calculate_rate(clicked_count, sent_count),
      bounce_rate: calculate_rate(bounced_count, sent_count)
    }
  end

  @doc """
  Gets email performance by type.
  """
  def get_performance_by_type(opts \\ []) do
    {start_date, end_date} = get_date_range(opts)
    
    # Get sent counts by email type
    sent_query = from es in EmailSend,
      where: es.sent_at >= ^start_date and es.sent_at <= ^end_date,
      group_by: es.email_type,
      select: {es.email_type, count(es.id)}
    
    sent_by_type = repo().all(sent_query) |> Enum.into(%{})
    
    # Get event counts by email type
    events_query = from ev in EmailEvent,
      join: es in EmailSend, on: ev.email_send_id == es.id,
      where: es.sent_at >= ^start_date and es.sent_at <= ^end_date,
      group_by: [es.email_type, ev.event_type],
      select: {es.email_type, ev.event_type, count(fragment("DISTINCT ?", ev.email_send_id))}
    
    events_data = repo().all(events_query)
    
    # Build performance data by type
    sent_by_type
    |> Enum.map(fn {email_type, sent_count} ->
      opened_count = get_event_count(events_data, email_type, "opened")
      clicked_count = get_event_count(events_data, email_type, "clicked")
      
      %{
        email_type: email_type,
        sent: sent_count,
        opened: opened_count,
        clicked: clicked_count,
        open_rate: calculate_rate(opened_count, sent_count),
        click_rate: calculate_rate(clicked_count, sent_count)
      }
    end)
  end

  @doc """
  Gets recent email activity.
  """
  def get_recent_activity(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50) |> min(1000)
    {start_date, end_date} = get_date_range(opts)
    
    query = from ev in EmailEvent,
      join: es in EmailSend, on: ev.email_send_id == es.id,
      where: es.sent_at >= ^start_date and es.sent_at <= ^end_date,
      order_by: [desc: ev.occurred_at],
      limit: ^limit,
      select: %{
        id: ev.id,
        event_type: ev.event_type,
        occurred_at: ev.occurred_at,
        email_type: es.email_type,
        recipient_email: es.recipient_email,
        click_url: ev.click_url
      }
    
    repo().all(query)
  end

  @doc """
  Gets email timeline data for charts.
  """
  def get_timeline_data(opts \\ []) do
    group_by = Keyword.get(opts, :group_by, :day)
    {start_date, end_date} = get_date_range(opts)
    
    date_trunc = case group_by do
      :hour -> "hour"
      :day -> "day"
      :week -> "week"
      :month -> "month"
    end
    
    # Get sent counts by date
    sent_query = from es in EmailSend,
      where: es.sent_at >= ^start_date and es.sent_at <= ^end_date,
      group_by: fragment("date_trunc(?, ?)", ^date_trunc, es.sent_at),
      select: {fragment("date_trunc(?, ?)", ^date_trunc, es.sent_at), count(es.id)}
    
    sent_by_date = repo().all(sent_query) |> Enum.into(%{})
    
    # Get event counts by date
    events_query = from ev in EmailEvent,
      join: es in EmailSend, on: ev.email_send_id == es.id,
      where: es.sent_at >= ^start_date and es.sent_at <= ^end_date,
      group_by: [fragment("date_trunc(?, ?)", ^date_trunc, es.sent_at), ev.event_type],
      select: {fragment("date_trunc(?, ?)", ^date_trunc, es.sent_at), ev.event_type, count(fragment("DISTINCT ?", ev.email_send_id))}
    
    events_data = repo().all(events_query)
    
    # Build timeline data
    sent_by_date
    |> Enum.map(fn {date, sent_count} ->
      opened_count = get_date_event_count(events_data, date, "opened")
      clicked_count = get_date_event_count(events_data, date, "clicked")
      
      %{
        date: date,
        sent: sent_count,
        opened: opened_count,
        clicked: clicked_count
      }
    end)
    |> Enum.sort_by(& &1.date)
  end

  @doc """
  Gets individual email details.
  """
  def get_email_details(email_send_id) do
    email_send = repo().get(EmailSend, email_send_id)
    
    if email_send do
      events_query = from ev in EmailEvent,
        where: ev.email_send_id == ^email_send_id,
        order_by: [desc: ev.occurred_at]
      
      events = repo().all(events_query)
      
      %{
        email_send: email_send,
        events: events,
        stats: calculate_email_stats(events)
      }
    else
      nil
    end
  end

  # Helper functions

  defp get_date_range(opts) do
    start_date = opts[:start_date] || DateTime.add(DateTime.utc_now(), -90, :day)
    end_date = opts[:end_date] || DateTime.utc_now()
    {start_date, end_date}
  end

  defp get_event_count(events_data, email_type, event_type) do
    events_data
    |> Enum.find({nil, nil, 0}, fn {et, evt, _count} -> 
      et == email_type && evt == event_type 
    end)
    |> elem(2)
  end

  defp get_date_event_count(events_data, date, event_type) do
    events_data
    |> Enum.find({nil, nil, 0}, fn {d, evt, _count} -> 
      d == date && evt == event_type 
    end)
    |> elem(2)
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