defmodule ExEmailTracker.Schemas.EmailSend do
  @moduledoc """
  Schema for tracking sent emails.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "ex_email_sends" do
    field :recipient_id, :integer
    field :recipient_email, :string
    field :email_type, :string
    field :subject, :string
    field :variant, :string
    field :metadata, :map, default: %{}
    field :sent_at, :utc_datetime_usec

    has_many :events, ExEmailTracker.Schemas.EmailEvent,
      foreign_key: :email_send_id

    timestamps(type: :utc_datetime_usec)
  end

  @required_fields ~w(id recipient_email email_type sent_at)a
  @optional_fields ~w(recipient_id subject variant metadata)a

  @doc false
  def changeset(email_send, attrs) do
    email_send
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_format(:recipient_email, ~r/@/)
    |> validate_length(:email_type, max: 50)
    |> validate_length(:variant, max: 50)
  end
end