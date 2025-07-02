defmodule ExEmailTracker.Schemas.EmailUnsubscribe do
  @moduledoc """
  Schema for tracking email unsubscribes.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "ex_email_unsubscribes" do
    field :recipient_email, :string
    field :email_type, :string
    field :unsubscribed_at, :utc_datetime_usec
    field :reason, :string

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  @required_fields ~w(recipient_email unsubscribed_at)a
  @optional_fields ~w(email_type reason)a

  @doc false
  def changeset(unsubscribe, attrs) do
    unsubscribe
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_format(:recipient_email, ~r/@/)
    |> validate_length(:email_type, max: 50)
    |> unique_constraint([:recipient_email, :email_type])
  end
end