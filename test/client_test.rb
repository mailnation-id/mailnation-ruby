# frozen_string_literal: true

require "minitest/autorun"
require "webrick"
require "mailnation"

class ClientTest < Minitest::Test
  def with_server(handler)
    server = WEBrick::HTTPServer.new(Port: 0, BindAddress: "127.0.0.1", AccessLog: [], Logger: WEBrick::Log.new(File::NULL))
    server.mount_proc("/", handler)
    thread = Thread.new { server.start }
    port = server.config[:Port]
    yield "http://127.0.0.1:#{port}"
  ensure
    server&.shutdown
    thread&.join
  end

  def test_send_and_get
    with_server(lambda { |req, res|
      if req.request_method == "POST" && req.path == "/emails"
        key = req["Idempotency-Key"]
        res.status = 202
        res["Content-Type"] = "application/json"
        res.body = { id: "01JTEST", status: "queued", source: "api", request_id: "req_send", idempotency_key: key }.to_json
      else
        res.status = 200
        res["Content-Type"] = "application/json"
        res.body = { id: "01JTEST", status: "delivered", request_id: "req_get" }.to_json
      end
    }) do |url|
      c = Mailnation::Client.new(username: "user", password: "pass", base_url: url)
      sent = c.emails.send(from: "noreply@example.com", to: "user@gmail.com", subject: "OTP", text: "847291")
      assert_equal "01JTEST", sent["id"]
      assert sent["idempotency_key"].start_with?("rb-")
      assert_equal "delivered", c.emails.get(sent["id"])["status"]
    end
  end

  def test_insufficient_credits
    with_server(lambda { |_req, res|
      res.status = 402
      res["Content-Type"] = "application/json"
      res.body = { error: "need credits", code: "insufficient_credits", request_id: "req_x" }.to_json
    }) do |url|
      c = Mailnation::Client.new(username: "u", password: "p", base_url: url)
      err = assert_raises(Mailnation::Error) do
        c.emails.send(from: "a@x.com", to: "b@x.com", subject: "x", text: "y")
      end
      assert err.insufficient_credits?
    end
  end
end
