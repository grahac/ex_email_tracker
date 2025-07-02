defmodule ExEmailTracker.Schemas.EmailLink do
  @moduledoc """
  Schema for tracking links within emails.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "ex_email_links" do
    field :email_send_id, :binary_id
    field :original_url, :string
    field :link_position, :integer
    field :link_text, :string

    belongs_to :email_send, ExEmailTracker.Schemas.EmailSend,
      foreign_key: :email_send_id,
      references: :id,
      define_field: false

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  @required_fields ~w(email_send_id original_url)a
  @optional_fields ~w(link_position link_text)a

  @doc false
  def changeset(link, attrs) do
    link
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:email_send_id)
  end
end