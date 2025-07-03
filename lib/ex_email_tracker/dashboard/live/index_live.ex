defmodule ExEmailTracker.Dashboard.IndexLive do
  @moduledoc """
  Main dashboard LiveView for email tracking analytics.
  """
  use Phoenix.LiveView
  alias ExEmailTracker.Analytics

  def mount(_params, _session, socket) do
    if connected?(socket) do
      case Application.get_env(:ex_email_tracker, :pubsub) do
        nil -> nil
        pubsub -> Phoenix.PubSub.subscribe(pubsub, "email_events")
      end
    end

    socket = 
      socket
      |> assign_filters()
      |> load_dashboard_data()

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    socket = 
      socket
      |> apply_filters(params)
      |> load_dashboard_data()

    {:noreply, socket}
  end

  def handle_event("filter", %{"filters" => filters}, socket) do
    query_params = build_query_params(filters)
    path = "/emails?#{URI.encode_query(query_params)}"
    
    {:noreply, push_navigate(socket, to: path)}
  end

  def handle_event("export", %{"format" => format}, socket) do
    # TODO: Implement export functionality
    {:noreply, put_flash(socket, :info, "Export in #{format} format coming soon!")}
  end

  def handle_info({:email_event, _event}, socket) do
    # Refresh data when new events come in
    {:noreply, load_dashboard_data(socket)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6 bg-gray-50 min-h-screen">
      <div class="max-w-7xl mx-auto">
        <div class="mb-8 flex justify-between items-start">
          <div>
            <h1 class="text-3xl font-bold text-gray-900">Email Analytics</h1>
            <p class="text-gray-600 mt-2">Track email performance and engagement metrics</p>
          </div>
          <div class="flex space-x-3">
            <a href="analytics" class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
              <svg class="-ml-1 mr-2 h-5 w-5 text-gray-500" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M3 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm0 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm0 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm0 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z" clip-rule="evenodd" />
              </svg>
              Analytics Table
            </a>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div class="p-6 bg-white rounded-lg shadow">
            <div class="text-sm font-medium text-gray-500">Total Sent</div>
            <div class="text-2xl font-bold text-gray-900"><%= @stats.sent %></div>
          </div>
          
          <div class="p-6 bg-white rounded-lg shadow">
            <div class="text-sm font-medium text-gray-500">Open Rate</div>
            <div class="text-2xl font-bold text-green-600"><%= @stats.open_rate %>%</div>
            <div class="text-sm text-gray-500"><%= @stats.opened %> opened</div>
          </div>
          
          <div class="p-6 bg-white rounded-lg shadow">
            <div class="text-sm font-medium text-gray-500">Click Rate</div>
            <div class="text-2xl font-bold text-blue-600"><%= @stats.click_rate %>%</div>
            <div class="text-sm text-gray-500"><%= @stats.clicked %> clicked</div>
          </div>
          
          <div class="p-6 bg-white rounded-lg shadow">
            <div class="text-sm font-medium text-gray-500">Bounce Rate</div>
            <div class="text-2xl font-bold text-red-600"><%= @stats.bounce_rate %>%</div>
            <div class="text-sm text-gray-500"><%= @stats.bounced %> bounced</div>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          <div class="p-6 bg-white rounded-lg shadow">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Performance by Email Type</h2>
            <div class="space-y-4">
              <%= for performance <- @performance_by_type do %>
                <div class="border-b border-gray-200 pb-3">
                  <div class="flex justify-between items-center mb-2">
                    <span class="font-medium text-gray-900"><%= performance.email_type %></span>
                    <span class="text-sm text-gray-500"><%= performance.sent %> sent</span>
                  </div>
                  <div class="flex space-x-4 text-sm">
                    <span class="text-green-600">Open: <%= performance.open_rate %>%</span>
                    <span class="text-blue-600">Click: <%= performance.click_rate %>%</span>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <div class="p-6 bg-white rounded-lg shadow">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Recent Activity</h2>
            <div class="space-y-3 max-h-80 overflow-y-auto">
              <%= for activity <- @recent_activity do %>
                <div class="flex items-center space-x-3 text-sm">
                  <span class={"px-2 py-1 rounded text-xs font-medium #{event_color(activity.event_type)}"}>
                    <%= activity.event_type %>
                  </span>
                  <span class="text-gray-600"><%= activity.email_type %></span>
                  <span class="text-gray-500 flex-1 truncate"><%= activity.recipient_email %></span>
                  <span class="text-gray-400"><%= relative_time(activity.occurred_at) %></span>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp assign_filters(socket) do
    assign(socket, :filters, %{
      date_range: "30",
      email_type: ""
    })
  end

  defp apply_filters(socket, params) do
    filters = %{
      date_range: params["date_range"] || socket.assigns.filters.date_range,
      email_type: params["email_type"] || socket.assigns.filters.email_type
    }
    
    assign(socket, :filters, filters)
  end

  defp load_dashboard_data(socket) do
    opts = build_analytics_opts(socket.assigns.filters)
    
    stats = Analytics.get_summary_stats(opts)
    performance_by_type = Analytics.get_performance_by_type(opts)
    recent_activity = Analytics.get_recent_activity(opts ++ [limit: 20])
    
    # Get unique email types for filter dropdown
    email_types = 
      performance_by_type
      |> Enum.map(& &1.email_type)
      |> Enum.sort()

    socket
    |> assign(:stats, stats)
    |> assign(:performance_by_type, performance_by_type)
    |> assign(:recent_activity, recent_activity)
    |> assign(:email_types, email_types)
  end

  defp build_analytics_opts(filters) do
    opts = []
    
    opts = 
      if filters.date_range != "" do
        days = String.to_integer(filters.date_range)
        start_date = DateTime.add(DateTime.utc_now(), -days, :day)
        [start_date: start_date] ++ opts
      else
        opts
      end
    
    opts = 
      if filters.email_type != "" do
        [email_type: filters.email_type] ++ opts
      else
        opts
      end
    
    opts
  end

  defp build_query_params(filters) do
    filters
    |> Enum.reject(fn {_k, v} -> v == "" end)
    |> Enum.into(%{})
  end

  defp event_color("opened"), do: "bg-green-100 text-green-800"
  defp event_color("clicked"), do: "bg-blue-100 text-blue-800"
  defp event_color("bounced"), do: "bg-red-100 text-red-800"
  defp event_color(_), do: "bg-gray-100 text-gray-800"

  defp relative_time(datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)
    
    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      true -> "#{div(diff, 86400)}d ago"
    end
  end
end