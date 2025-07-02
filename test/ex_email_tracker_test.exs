defmodule ExEmailTrackerTest do
  use ExUnit.Case
  doctest ExEmailTracker

  alias ExEmailTracker.Schemas.{EmailSend, EmailEvent}
  
  setup do
    # Clean up before each test
    ExEmailTracker.TestRepo.delete_all(EmailEvent)
    ExEmailTracker.TestRepo.delete_all(EmailSend)
    :ok
  end

  test "track/2 adds tracking to email" do
    email = %Swoosh.Email{
      to: [{"Test User", "test@example.com"}],
      subject: "Test Email",
      html_body: "<p>Hello <a href='https://example.com'>click here</a></p>"
    }

    tracked_email = ExEmailTracker.track(email, email_type: :test_email)
    
    # Should have tracking pixel
    assert String.contains?(tracked_email.html_body, "track/open/")
    
    # Should have rewritten links
    assert String.contains?(tracked_email.html_body, "track/click/")
    
    # Should have tracking headers
    assert List.keyfind(tracked_email.headers, "X-Email-Track-ID", 0)
    
    # Should have created email send record
    assert ExEmailTracker.TestRepo.aggregate(EmailSend, :count) == 1
  end

  test "track/2 with skip_tracking option" do
    email = %Swoosh.Email{
      to: [{"Test User", "test@example.com"}],
      subject: "Test Email",
      html_body: "<p>Hello</p>"
    }

    tracked_email = ExEmailTracker.track(email, email_type: :test_email, skip_tracking: true)
    
    # Should be unchanged
    assert tracked_email == email
    
    # Should not have created email send record
    assert ExEmailTracker.TestRepo.aggregate(EmailSend, :count) == 0
  end

  test "config functions" do
    assert ExEmailTracker.repo() == ExEmailTracker.TestRepo
    assert ExEmailTracker.base_url() == "http://localhost:4000"
  end
end