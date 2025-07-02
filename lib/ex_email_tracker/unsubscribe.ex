defmodule ExEmailTracker.Unsubscribe do
  @moduledoc """
  Helper functions for managing email unsubscribes.
  """
  import Ecto.Query
  alias ExEmailTracker.Schemas.EmailUnsubscribe

  @doc """
  Checks if an email address is unsubscribed from a specific email type.
  
  ## Examples
  
      iex> ExEmailTracker.Unsubscribe.unsubscribed?("user@example.com", :marketing)
      false
      
      iex> ExEmailTracker.Unsubscribe.unsubscribed?("user@example.com", "newsletter")
      true
  """
  def unsubscribed?(email, email_type) do
    email_type = to_string(email_type)
    
    repo().exists?(
      from u in EmailUnsubscribe,
      where: u.recipient_email == ^email and 
             (is_nil(u.email_type) or u.email_type == ^email_type)
    )
  end

  @doc """
  Lists all unsubscribed email types for a given email address.
  
  ## Examples
  
      iex> ExEmailTracker.Unsubscribe.unsubscribed_types("user@example.com")
      ["marketing", "newsletter"]
  """
  def unsubscribed_types(email) do
    repo().all(
      from u in EmailUnsubscribe,
      where: u.recipient_email == ^email,
      select: u.email_type
    )
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Manually unsubscribes an email from a specific type.
  
  ## Examples
  
      iex> ExEmailTracker.Unsubscribe.unsubscribe("user@example.com", :marketing)
      {:ok, %EmailUnsubscribe{}}
  """
  def unsubscribe(email, email_type, reason \\ "manual") do
    attrs = %{
      recipient_email: email,
      email_type: to_string(email_type),
      unsubscribed_at: DateTime.utc_now(),
      reason: reason
    }

    %EmailUnsubscribe{}
    |> EmailUnsubscribe.changeset(attrs)
    |> repo().insert(on_conflict: :nothing)
  end

  @doc """
  Resubscribes an email to a specific type by removing the unsubscribe record.
  
  ## Examples
  
      iex> ExEmailTracker.Unsubscribe.resubscribe("user@example.com", :marketing)
      {1, nil}
  """
  def resubscribe(email, email_type) do
    email_type = to_string(email_type)
    
    repo().delete_all(
      from u in EmailUnsubscribe,
      where: u.recipient_email == ^email and u.email_type == ^email_type
    )
  end

  defp repo do
    ExEmailTracker.repo()
  end
end