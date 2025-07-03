defmodule ExEmailTracker do
  @moduledoc """
  ExEmailTracker provides comprehensive email tracking capabilities for Phoenix/LiveView 
  applications using Swoosh.

  ## Features

  - Open tracking via invisible pixel
  - Click tracking with URL preservation
  - Bounce and unsubscribe handling
  - Real-time analytics dashboard
  - GDPR compliant with privacy controls

  ## Usage

      # Add tracking to any Swoosh email
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
  """

  alias ExEmailTracker.Tracker

  @doc """
  Adds tracking to a Swoosh email.

  ## Options

    * `:recipient_id` - ID of the recipient (optional)
    * `:email_type` - Type of email being sent (required)
    * `:metadata` - Additional metadata to store (optional)
    * `:variant` - A/B test variant (optional)
    * `:skip_tracking` - Skip tracking for this email (optional)

  ## Examples

      iex> email = %Swoosh.Email{to: [{"Test", "test@example.com"}], subject: "Test", html_body: "<p>Hello</p>"}
      iex> tracked = ExEmailTracker.track(email, email_type: :welcome_email)
      iex> is_struct(tracked, Swoosh.Email)
      true

  """
  @spec track(Swoosh.Email.t(), keyword()) :: Swoosh.Email.t()
  def track(email, opts) do
    Tracker.track_email(email, opts)
  end

  @doc """
  Returns the configuration for ExEmailTracker.
  """
  def config do
    Application.get_all_env(:ex_email_tracker)
  end

  @doc """
  Returns the configured Ecto repo.
  """
  def repo do
    config()[:repo] || raise "ExEmailTracker requires a repo to be configured"
  end

  @doc """
  Returns the base URL for tracking links.
  """
  def base_url do
    config()[:base_url] || raise "ExEmailTracker requires a base_url to be configured"
  end
end