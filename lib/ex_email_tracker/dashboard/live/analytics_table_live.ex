defmodule ExEmailTracker.Dashboard.AnalyticsTableLive do
  use Phoenix.LiveView
  alias ExEmailTracker.Analytics

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()
    
    socket = 
      socket
      |> assign(:page_title, "Email Analytics Table")
      |> assign(:view_mode, "summary")
      |> assign(:date_filter, "today")
      |> assign(:start_date, today)
      |> assign(:end_date, today)
      |> assign(:custom_start_date, today)
      |> assign(:custom_end_date, today)
      |> assign(:selected_email_type, nil)
      |> assign(:dropdown_open, false)
      |> assign(:search_term, "")
      |> load_analytics_data()

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_dropdown", _params, socket) do
    {:noreply, assign(socket, :dropdown_open, !socket.assigns.dropdown_open)}
  end

  def handle_event("close_dropdown", _params, socket) do
    {:noreply, assign(socket, :dropdown_open, false)}
  end

  def handle_event("filter_date", params, socket) do
    IO.inspect(params, label: "filter_date params")
    filter = params["date_filter"]
    {start_date, end_date} = get_date_range_for_filter(filter)
    
    socket = 
      socket
      |> assign(:date_filter, filter)
      |> assign(:start_date, start_date)
      |> assign(:end_date, end_date)
      |> assign(:dropdown_open, false)
      |> load_analytics_data()

    {:noreply, socket}
  end

  def handle_event("set_custom_dates", %{"start_date" => start_str, "end_date" => end_str}, socket) do
    with {:ok, start_date} <- Date.from_iso8601(start_str),
         {:ok, end_date} <- Date.from_iso8601(end_str) do
      
      socket = 
        socket
        |> assign(:date_filter, "custom")
        |> assign(:start_date, start_date)
        |> assign(:end_date, end_date)
        |> assign(:custom_start_date, start_date)
        |> assign(:custom_end_date, end_date)
        |> load_analytics_data()

      {:noreply, socket}
    else
      _ ->
        {:noreply, put_flash(socket, :error, "Invalid date format")}
    end
  end

  def handle_event("toggle_view", %{"mode" => mode}, socket) do
    socket = 
      socket
      |> assign(:view_mode, mode)
      |> assign(:search_term, "")  # Clear search when switching views
      |> load_analytics_data()

    {:noreply, socket}
  end

  def handle_event("drill_down", %{"email_type" => email_type}, socket) do
    socket = 
      socket
      |> assign(:selected_email_type, email_type)
      |> assign(:view_mode, "detail")
      |> load_analytics_data()

    {:noreply, socket}
  end

  def handle_event("clear_drill_down", _params, socket) do
    socket = 
      socket
      |> assign(:selected_email_type, nil)
      |> assign(:view_mode, "summary")
      |> load_analytics_data()

    {:noreply, socket}
  end

  def handle_event("search", %{"search" => search_term}, socket) do
    socket = 
      socket
      |> assign(:search_term, search_term)
      |> load_analytics_data()

    {:noreply, socket}
  end

  defp load_analytics_data(socket) do
    start_datetime = DateTime.new!(socket.assigns.start_date, ~T[00:00:00], "Etc/UTC")
    end_datetime = DateTime.new!(socket.assigns.end_date, ~T[23:59:59], "Etc/UTC")
    
    opts = [start_date: start_datetime, end_date: end_datetime]

    case socket.assigns.view_mode do
      "detail" ->
        opts_with_search = opts ++ [search: socket.assigns.search_term]
        data = Analytics.get_email_performance_grid(opts_with_search)
        filtered_data = if socket.assigns.selected_email_type do
          Enum.filter(data, &(&1.email_type == socket.assigns.selected_email_type))
        else
          data
        end
        assign(socket, :analytics_data, filtered_data)
      
      "summary" ->
        data = Analytics.get_email_performance_summary(opts)
        assign(socket, :analytics_data, data)
    end
  end

  defp get_date_range_for_filter("today") do
    now = DateTime.utc_now()
    start_time = DateTime.add(now, -24, :hour)
    {DateTime.to_date(start_time), DateTime.to_date(now)}
  end

  defp get_date_range_for_filter("yesterday") do
    now = DateTime.utc_now()
    start_time = DateTime.add(now, -48, :hour)
    end_time = DateTime.add(now, -24, :hour)
    {DateTime.to_date(start_time), DateTime.to_date(end_time)}
  end

  defp get_date_range_for_filter("last_7_days") do
    now = DateTime.utc_now()
    start_time = DateTime.add(now, -7 * 24, :hour)
    {DateTime.to_date(start_time), DateTime.to_date(now)}
  end

  defp get_date_range_for_filter("last_30_days") do
    now = DateTime.utc_now()
    start_time = DateTime.add(now, -30 * 24, :hour)
    {DateTime.to_date(start_time), DateTime.to_date(now)}
  end

  defp get_date_range_for_filter(_) do
    now = DateTime.utc_now()
    start_time = DateTime.add(now, -24, :hour)
    {DateTime.to_date(start_time), DateTime.to_date(now)}
  end

  defp format_date(date) when is_struct(date, Date) do
    Date.to_string(date)
  end

  defp format_date(datetime) when is_struct(datetime, DateTime) do
    datetime
    |> DateTime.to_date()
    |> Date.to_string()
  end

  defp format_date(naive_datetime) when is_struct(naive_datetime, NaiveDateTime) do
    naive_datetime
    |> NaiveDateTime.to_date()
    |> Date.to_string()
  end

  defp format_datetime(datetime) when is_struct(datetime, DateTime) do
    datetime
    |> DateTime.truncate(:second)
    |> DateTime.to_string()
  end

  defp format_rate(rate) when is_number(rate) do
    "#{:erlang.float_to_binary(rate, decimals: 1)}%"
  end

  defp format_rate(_), do: "0.0%"

  defp get_filter_label("today"), do: "Today"
  defp get_filter_label("yesterday"), do: "Yesterday"
  defp get_filter_label("last_7_days"), do: "Last 7 Days"
  defp get_filter_label("last_30_days"), do: "Last 30 Days"
  defp get_filter_label("custom"), do: "Custom Range"
  defp get_filter_label(_), do: "Today"
end