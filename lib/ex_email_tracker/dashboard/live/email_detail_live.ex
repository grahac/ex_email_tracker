defmodule ExEmailTracker.Dashboard.EmailDetailLive do
  @moduledoc """
  Email detail view showing individual email tracking information.
  """
  use Phoenix.LiveView
  alias ExEmailTracker.Analytics

  def mount(%{"id" => email_send_id}, _session, socket) do
    case Analytics.get_email_details(email_send_id) do
      nil ->
        {:ok, 
         socket
         |> put_flash(:error, "Email not found")
         |> push_navigate(to: "/emails")}
        
      email_details ->
        {:ok, assign(socket, :email_details, email_details)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="p-6 bg-gray-50 min-h-screen">
      <div class="max-w-4xl mx-auto">
        <div class="mb-6">
          <h1 class="text-2xl font-bold text-gray-900">Email Details</h1>
        </div>

        <div class="bg-white rounded-lg shadow mb-6 p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Email Information</h2>
          <dl class="space-y-2">
            <div>
              <dt class="text-sm font-medium text-gray-500">Subject</dt>
              <dd class="text-sm text-gray-900"><%= @email_details.email_send.subject || "No subject" %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Type</dt>
              <dd class="text-sm text-gray-900"><%= @email_details.email_send.email_type %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Recipient</dt>
              <dd class="text-sm text-gray-900"><%= @email_details.email_send.recipient_email %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Sent At</dt>
              <dd class="text-sm text-gray-900"><%= format_datetime(@email_details.email_send.sent_at) %></dd>
            </div>
          </dl>
        </div>

        <div class="bg-white rounded-lg shadow p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Event Timeline</h2>
          
          <%= if Enum.empty?(@email_details.events) do %>
            <p class="text-gray-500 text-center py-8">No tracking events recorded yet.</p>
          <% else %>
            <div class="space-y-4">
              <%= for event <- @email_details.events do %>
                <div class="flex items-start space-x-4 p-4 border border-gray-200 rounded-lg">
                  <div class={"w-10 h-10 rounded-full flex items-center justify-center text-white text-sm font-medium #{event_bg_color(event.event_type)}"}>
                    <%= event_icon(event.event_type) %>
                  </div>
                  
                  <div class="flex-1">
                    <div class="flex items-center space-x-2 mb-1">
                      <span class="font-medium text-gray-900"><%= String.capitalize(event.event_type) %></span>
                      <span class="text-sm text-gray-500"><%= format_datetime(event.occurred_at) %></span>
                    </div>
                    
                    <%= if event.click_url do %>
                      <div class="text-sm text-gray-600">
                        Clicked: <a href={event.click_url} target="_blank" class="text-blue-600 hover:underline"><%= event.click_url %></a>
                      </div>
                    <% end %>
                    
                    <%= if event.user_agent do %>
                      <div class="text-xs text-gray-500 mt-1">
                        User Agent: <%= event.user_agent %>
                      </div>
                    <% end %>
                    
                    <%= if event.ip_address do %>
                      <div class="text-xs text-gray-500">
                        IP: <%= event.ip_address %>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp event_bg_color("opened"), do: "bg-green-500"
  defp event_bg_color("clicked"), do: "bg-blue-500"
  defp event_bg_color("bounced"), do: "bg-red-500"
  defp event_bg_color(_), do: "bg-gray-500"

  defp event_icon("opened"), do: "👁"
  defp event_icon("clicked"), do: "🔗"
  defp event_icon("bounced"), do: "⚠"
  defp event_icon(_), do: "📧"

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")
  end
end