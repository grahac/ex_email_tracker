defmodule ExEmailTrackerTest do
  use ExUnit.Case
  doctest ExEmailTracker

  setup do
    # Each test gets its own transaction
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ExEmailTracker.TestRepo)
    :ok
  end

  test "config functions" do
    assert ExEmailTracker.base_url() == "http://localhost:4000"
  end
end