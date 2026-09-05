defmodule ExEmailTracker.Plug.TrackOpenTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias ExEmailTracker.Plug.TrackOpen

  describe "call/2" do
    test "returns transparent pixel for valid UUID" do
      uuid = Ecto.UUID.generate()

      conn =
        :get
        |> conn("/track/open/#{uuid}")
        |> Map.put(:params, %{"email_send_id" => uuid})

      # We expect it to try to record the event (which will fail without a DB record)
      # but still return the pixel
      conn = TrackOpen.call(conn, [])

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["image/png"]
      assert get_resp_header(conn, "cache-control") == ["no-cache, no-store, must-revalidate"]
    end

    test "returns transparent pixel for Base64-encoded UUID" do
      uuid = Ecto.UUID.generate()
      encoded_uuid = Base.url_encode64(uuid, padding: false)

      conn =
        :get
        |> conn("/track/open/#{encoded_uuid}")
        |> Map.put(:params, %{"email_send_id" => encoded_uuid})

      conn = TrackOpen.call(conn, [])

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["image/png"]
    end

    test "returns transparent pixel for invalid Base64" do
      invalid_id = "invalid!!!base64"

      conn =
        :get
        |> conn("/track/open/#{invalid_id}")
        |> Map.put(:params, %{"email_send_id" => invalid_id})

      conn = TrackOpen.call(conn, [])

      # Should still return pixel even with invalid ID
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["image/png"]
    end

    test "returns transparent pixel for Base64 that doesn't decode to UUID" do
      # Valid Base64 but not a UUID
      encoded = Base.url_encode64("not-a-uuid", padding: false)

      conn =
        :get
        |> conn("/track/open/#{encoded}")
        |> Map.put(:params, %{"email_send_id" => encoded})

      conn = TrackOpen.call(conn, [])

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["image/png"]
    end

    test "passes through connections without email_send_id parameter" do
      conn = conn(:get, "/track/open")
      conn = TrackOpen.call(conn, [])

      # Should pass through without modification
      assert conn.status == nil
      refute conn.halted
    end

    test "pixel response has correct headers and body" do
      uuid = Ecto.UUID.generate()

      conn =
        :get
        |> conn("/track/open/#{uuid}")
        |> Map.put(:params, %{"email_send_id" => uuid})

      conn = TrackOpen.call(conn, [])

      assert get_resp_header(conn, "pragma") == ["no-cache"]
      assert get_resp_header(conn, "expires") == ["0"]

      # Verify it's actually a PNG (check PNG signature)
      assert byte_size(conn.resp_body) > 0
      <<137, 80, 78, 71, _rest::binary>> = conn.resp_body
    end
  end
end
