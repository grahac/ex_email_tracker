ExUnit.start()

# Configure test repo
defmodule ExEmailTracker.TestRepo do
  use Ecto.Repo,
    otp_app: :ex_email_tracker,
    adapter: Ecto.Adapters.Postgres
end

# Start test repo
ExEmailTracker.TestRepo.start_link()

# Configure ExEmailTracker for tests
Application.put_env(:ex_email_tracker, :repo, ExEmailTracker.TestRepo)
Application.put_env(:ex_email_tracker, :base_url, "http://localhost:4000")

# Run migrations
path = Application.app_dir(:ex_email_tracker, "priv/test_migrations")
Ecto.Migrator.run(ExEmailTracker.TestRepo, path, :up, all: true)