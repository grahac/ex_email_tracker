defmodule ExEmailTracker.Schemas.EmailEvent do
  @moduledoc """
  Schema for tracking email events (opens, clicks, bounces, etc).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @event_types ~w(opened clicked bounced complained unsubscribed)

  schema "ex_email_events" do
    field :email_send_id, :binary_id
    field :event_type, :string
    field :occurred_at, :utc_datetime_usec
    field :ip_address, :string
    field :user_agent, :string
    field :click_url, :string
    field :metadata, :map, default: %{}

    belongs_to :email_send, ExEmailTracker.Schemas.EmailSend,
      foreign_key: :email_send_id,
      references: :id,
      define_field: false

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  @required_fields ~w(email_send_id event_type occurred_at)a
  @optional_fields ~w(ip_address user_agent click_url metadata)a

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:event_type, @event_types)
    |> validate_length(:event_type, max: 20)
    |> foreign_key_constraint(:email_send_id)
  end
end