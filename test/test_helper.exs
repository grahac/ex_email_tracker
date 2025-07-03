ExUnit.start()

# Configure test repo
defmodule ExEmailTracker.TestRepo do
  use Ecto.Repo,
    otp_app: :ex_email_tracker,
    adapter: Ecto.Adapters.Postgres
end

# Configure test database
Application.put_env(:ex_email_tracker, ExEmailTracker.TestRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "ex_email_tracker_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
)

# Configure ExEmailTracker for tests
Application.put_env(:ex_email_tracker, :repo, ExEmailTracker.TestRepo)
Application.put_env(:ex_email_tracker, :base_url, "http://localhost:4000")

# Start test repo
{:ok, _} = ExEmailTracker.TestRepo.start_link()

# Create test database if it doesn't exist
case Ecto.Adapters.Postgres.storage_up(ExEmailTracker.TestRepo.config()) do
  :ok -> :ok
  {:error, :already_up} -> :ok
  {:error, term} -> raise "Could not create test database: #{inspect(term)}"
end

# Run migrations using the migration module - only if tables don't exist
case ExEmailTracker.TestRepo.query("SELECT 1 FROM ex_email_sends LIMIT 1") do
  {:ok, _} -> 
    # Tables exist, do nothing
    :ok
  {:error, %Postgrex.Error{postgres: %{code: :undefined_table}}} ->
    # Tables don't exist, create them
    IO.puts("Creating test database tables...")
    
    # Create a temporary migration module for testing
    defmodule TestMigration do
      use Ecto.Migration
      
      def change do
        ExEmailTracker.Migration.up()
      end
    end
    
    # Run the migration
    Ecto.Migrator.run(ExEmailTracker.TestRepo, [{0, TestMigration}], :up, all: true)
    IO.puts("Test database tables created successfully!")
  {:error, error} ->
    raise "Unexpected database error: #{inspect(error)}"
end

# Set up test mode for database
Ecto.Adapters.SQL.Sandbox.mode(ExEmailTracker.TestRepo, :manual)