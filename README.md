# ExEmailTracker

[![Hex.pm](https://img.shields.io/hexpm/v/ex_email_tracker.svg)](https://hex.pm/packages/ex_email_tracker)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/ex_email_tracker)
[![CI](https://github.com/yourusername/ex_email_tracker/actions/workflows/ci.yml/badge.svg)](https://github.com/yourusername/ex_email_tracker/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

ExEmailTracker provides comprehensive email tracking capabilities for Phoenix/LiveView applications using Swoosh. Track email opens, clicks, and engagement metrics with minimal code changes and includes a ready-to-use analytics dashboard.

## Features

- **Easy Integration**: One-line tracking for any Swoosh email
- **Open Tracking**: Track when emails are opened via invisible pixel
- **Click Tracking**: Track all link clicks with original URL preservation
- **Analytics Dashboard**: Plug-and-play LiveView dashboard with real-time metrics
- **Privacy Compliant**: GDPR compliant with built-in privacy controls
- **Works with All Adapters**: Compatible with all Swoosh email providers

## Installation

Add `ex_email_tracker` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_email_tracker, "~> 0.1.0"}
  ]
end
```

## Quick Start

### 1. Create Database Migration

Generate a new migration in your application:

```bash
mix ecto.gen.migration create_ex_email_tracker_tables
```

Then update the generated migration file:

```elixir
defmodule YourApp.Repo.Migrations.CreateExEmailTrackerTables do
  use Ecto.Migration
  
  def up do
    ExEmailTracker.Migration.up()
  end
  
  def down do
    ExEmailTracker.Migration.down()
  end
end
```

Run the migration:

```bash
mix ecto.migrate
```

### 2. Configure Your Application

Add configuration to `config/config.exs`:

```elixir
config :ex_email_tracker,
  repo: MyApp.Repo,
  base_url: "https://myapp.com"
```

### 3. Add Tracking to Your Emails

In your Swoosh mailer:

```elixir
def deliver_welcome_email(user) do
  new()
  |> to(user.email)
  |> subject("Welcome!")
  |> html_body("<p>Welcome! <a href='https://app.com'>Visit our app</a></p>")
  |> ExEmailTracker.track(
    recipient_id: user.id,
    email_type: :welcome_email,
    metadata: %{organization_id: user.organization_id}
  )
  |> Mailer.deliver()
end
```

### 4. Add Routes

In your `router.ex`:

```elixir
# REQUIRED: Add tracking endpoints at the root level
import ExEmailTracker.Router
ex_email_tracker_endpoints()

# OPTIONAL: Add admin dashboard (in a protected scope)
scope "/admin" do
  pipe_through [:browser, :require_authenticated_user]
  
  import ExEmailTracker.Router
  ex_email_tracker_dashboard "/emails"
end
```

**⚠️ Important:** The tracking endpoints (`ex_email_tracker_endpoints()`) must be added at the root level of your router, not inside any scope. This ensures they're accessible at `/track/open/:id`, `/track/click/:id/:link_id`, and `/track/unsubscribe/:id` which is where the tracking URLs point to.

## Dashboard

The analytics dashboard provides:

- **Summary Metrics**: Total sent, open rates, click rates, bounce rates
- **Performance by Type**: Compare different email types
- **Real-time Activity**: Live feed of email events
- **Individual Email Details**: Timeline view of each email's journey
- **Export Capabilities**: Download analytics as CSV

## Configuration Options

```elixir
config :ex_email_tracker,
  repo: MyApp.Repo,
  base_url: "https://myapp.com",
  pubsub: MyApp.PubSub,           # Optional: for real-time dashboard updates
  track_opens: true,              # Enable/disable open tracking
  track_clicks: true,             # Enable/disable click tracking
  add_unsubscribe: true,          # Add unsubscribe links
  retention_days: 90,             # Auto-delete old data
  anonymize_ips: true,            # GDPR compliance
  
  # Unsubscribe handling
  unsubscribe_redirect_url: "https://myapp.com/unsubscribe/success",
  # Or use a function for dynamic URLs:
  # unsubscribe_redirect_url: &MyApp.build_unsubscribe_url/1,
  
  # Callback when someone unsubscribes
  unsubscribe_callback: &MyApp.handle_unsubscribe/1
```

### Unsubscribe Integration

Configure callbacks to sync with your application:

```elixir
# In your application
defmodule MyApp do
  def handle_unsubscribe(%{email: email, email_type: type, recipient_id: id}) do
    # Update your user preferences
    Users.update_email_preferences(id, %{type => false})
    
    # Log the event
    Logger.info("User #{id} unsubscribed from #{type} emails")
  end
  
  def build_unsubscribe_url(email_send) do
    # Dynamic URL based on email data
    "https://myapp.com/settings/emails?unsubscribed=#{email_send.email_type}"
  end
end
```

### Automatic Unsubscribe Checking

Enable automatic suppression of emails to unsubscribed users:

```elixir
config :ex_email_tracker,
  check_unsubscribes: true  # Automatically suppress emails to unsubscribed users
```

When enabled, `ExEmailTracker.track/2` will return `nil` for unsubscribed recipients:

```elixir
# This will return nil if user is unsubscribed from marketing emails
tracked_email = email |> ExEmailTracker.track(email_type: :marketing)

if tracked_email do
  Mailer.deliver(tracked_email)
end
```

### Manual Unsubscribe Management

Use the `ExEmailTracker.Unsubscribe` module for manual control:

```elixir
# Check if unsubscribed
ExEmailTracker.Unsubscribe.unsubscribed?("user@example.com", :marketing)
# => true/false

# Manually unsubscribe
ExEmailTracker.Unsubscribe.unsubscribe("user@example.com", :newsletter)

# Resubscribe (e.g., from settings page)
ExEmailTracker.Unsubscribe.resubscribe("user@example.com", :newsletter)

# Get all unsubscribed types for a user
ExEmailTracker.Unsubscribe.unsubscribed_types("user@example.com")
# => ["marketing", "newsletter"]
```

## API Reference

### ExEmailTracker.track/2

Adds tracking to a Swoosh email.

**Options:**
- `:recipient_id` - ID of the recipient (optional)
- `:email_type` - Type of email being sent (required, use atoms like `:welcome_email`)
- `:metadata` - Additional metadata to store (optional)
- `:variant` - A/B test variant (optional)
- `:skip_tracking` - Skip tracking for this email (optional)

**Note on email_type**: While both atoms and strings are supported, atoms are recommended for consistency and to prevent typos:

```elixir
# Recommended
|> ExEmailTracker.track(email_type: :welcome_email)

# Also works
|> ExEmailTracker.track(email_type: "welcome_email")
```

### ExEmailTracker.Analytics

Query interface for analytics data:

```elixir
# Get summary statistics
ExEmailTracker.Analytics.get_summary_stats(
  start_date: ~D[2024-01-01],
  end_date: ~D[2024-12-31],
  email_type: "welcome_email"
)

# Get performance by email type
ExEmailTracker.Analytics.get_performance_by_type()

# Get recent activity
ExEmailTracker.Analytics.get_recent_activity(limit: 20)

# Get timeline data for charts
ExEmailTracker.Analytics.get_timeline_data(group_by: :day)
```

## Privacy & Compliance

ExEmailTracker is designed with privacy in mind:

- **IP Anonymization**: Optionally anonymize IP addresses
- **Data Retention**: Automatic cleanup of old tracking data
- **Unsubscribe Handling**: Built-in unsubscribe link management
- **Opt-out Support**: Per-recipient tracking preferences
- **Transparent Tracking**: Clear disclosure options

## Testing

```bash
mix test
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

MIT License. See [LICENSE](LICENSE) for details.

## Support

- [Documentation](https://hexdocs.pm/ex_email_tracker)
- [Issue Tracker](https://github.com/yourusername/ex_email_tracker/issues)
- [Discussions](https://github.com/yourusername/ex_email_tracker/discussions)