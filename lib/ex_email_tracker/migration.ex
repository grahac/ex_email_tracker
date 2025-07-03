defmodule ExEmailTracker.Migration do
  @moduledoc """
  Migration module for ExEmailTracker tables.
  
  To use this in your application, create a new migration:
  
      mix ecto.gen.migration create_ex_email_tracker_tables
  
  Then in the generated migration file:
  
      defmodule YourApp.Repo.Migrations.CreateExEmailTrackerTables do
        use Ecto.Migration
        
        def up do
          ExEmailTracker.Migration.up()
        end
        
        def down do
          ExEmailTracker.Migration.down()
        end
      end
  """

  use Ecto.Migration

  def up do
    # Create email sends table
    create table(:ex_email_sends, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :recipient_id, :bigint
      add :recipient_email, :text, null: false
      add :email_type, :string, size: 50, null: false
      add :subject, :text
      add :variant, :string, size: 50
      add :metadata, :jsonb, default: "{}"
      add :sent_at, :utc_datetime_usec, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:ex_email_sends, [:recipient_email])
    create index(:ex_email_sends, [:email_type])
    create index(:ex_email_sends, [:sent_at])
    create index(:ex_email_sends, [:recipient_id])
    
    # Composite indexes for analytics performance
    create index(:ex_email_sends, [:email_type, :sent_at])
    create index(:ex_email_sends, [:sent_at, :email_type])
    create index(:ex_email_sends, [:recipient_id, :sent_at])

    # Create email events table
    create table(:ex_email_events) do
      add :email_send_id, references(:ex_email_sends, type: :uuid, on_delete: :delete_all), null: false
      add :event_type, :string, size: 20, null: false
      add :occurred_at, :utc_datetime_usec, null: false
      add :ip_address, :string
      add :user_agent, :text
      add :click_url, :text
      add :metadata, :jsonb, default: "{}"

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:ex_email_events, [:email_send_id])
    create index(:ex_email_events, [:event_type])
    create index(:ex_email_events, [:occurred_at])
    
    # Composite indexes for analytics joins
    create index(:ex_email_events, [:email_send_id, :event_type])
    create index(:ex_email_events, [:event_type, :occurred_at])
    create index(:ex_email_events, [:occurred_at, :event_type])

    # Create email links table
    create table(:ex_email_links) do
      add :email_send_id, references(:ex_email_sends, type: :uuid, on_delete: :delete_all), null: false
      add :original_url, :text, null: false
      add :link_position, :integer
      add :link_text, :text

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:ex_email_links, [:email_send_id])

    # Create email unsubscribes table
    create table(:ex_email_unsubscribes) do
      add :recipient_email, :text, null: false
      add :email_type, :string, size: 50
      add :unsubscribed_at, :utc_datetime_usec, null: false
      add :reason, :text

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:ex_email_unsubscribes, [:recipient_email, :email_type])
    create index(:ex_email_unsubscribes, [:recipient_email])
  end

  def down do
    drop table(:ex_email_unsubscribes)
    drop table(:ex_email_links)
    drop table(:ex_email_events)
    drop table(:ex_email_sends)
  end
end