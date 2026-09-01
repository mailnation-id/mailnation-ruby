# frozen_string_literal: true

require "json"
require "net/http"
require "uri"
require "base64"
require "securerandom"

module Mailnation
  DEFAULT_BASE_URL = "https://api.mailnation.id"

  class Error < StandardError
    attr_reader :status_code, :code, :request_id

    def initialize(message, code: "", status_code: 0, request_id: "")
      @status_code = status_code
      @code = code
      @request_id = request_id
      extra = request_id.empty? ? "" : " request_id=#{request_id}"
      super("mailnation: #{message} (#{code}) status=#{status_code}#{extra}")
    end

    def insufficient_credits? = code == "insufficient_credits"
    def idempotency_conflict? = code == "idempotency_conflict"
    def retryable?
      %w[rate_limited service_unavailable temporary_failure idempotency_in_progress].include?(code) ||
        [429, 502, 503, 504].include?(status_code)
    end
  end

  class Emails
    def initialize(client)
      @client = client
    end

    def send(req)
      raise ArgumentError, "mailnation: from is required" if req[:from].to_s.empty? && req["from"].to_s.empty?
      to = req[:to] || req["to"]
      raise ArgumentError, "mailnation: to is required" if to.nil? || to == [] || to == ""
      raise ArgumentError, "mailnation: subject is required" if (req[:subject] || req["subject"]).to_s.empty?

      body = stringify_keys(req)
      key = body.delete("idempotency_key")
      key = "rb-#{SecureRandom.uuid}" if key.to_s.empty?
      @client.request("POST", "/emails", body, { "Idempotency-Key" => key })
    end

    def get(id)
      raise ArgumentError, "mailnation: id is required" if id.to_s.empty?

      @client.request("GET", "/emails/#{URI.encode_www_form_component(id)}")
    end

    def wait(id, interval: 2, terminal: %w[delivered partial failed])
      loop do
        email = get(id)
        return email if terminal.include?(email["status"])

        sleep interval
      end
    end

    def self.attachment_from_file(path, content_type = nil)
      att = {
        "filename" => File.basename(path),
        "content" => Base64.strict_encode64(File.binread(path))
      }
      att["content_type"] = content_type if content_type
      att
    end

    private

    def stringify_keys(h)
      h.each_with_object({}) { |(k, v), acc| acc[k.to_s] = v }
    end
  end

  class Client
    attr_reader :emails

    def initialize(username: nil, password: nil, bearer: nil, base_url: DEFAULT_BASE_URL)
      @base_url = base_url.sub(%r{/+\z}, "")
      @username = username.to_s
      @password = password.to_s
      @bearer = bearer.to_s
      @emails = Emails.new(self)
    end

    def request(method, path, body = nil, headers = {})
      uri = URI.parse(@base_url + path)
      req = Net::HTTP.const_get(method.capitalize).new(uri)
      req["Accept"] = "application/json"
      req["User-Agent"] = "mailnation-ruby"
      headers.each { |k, v| req[k] = v }
      if body
        req["Content-Type"] = "application/json"
        req.body = JSON.generate(body)
      end
      if !@bearer.empty?
        req["Authorization"] = "Bearer #{@bearer}"
      elsif !@username.empty? || !@password.empty?
        req.basic_auth(@username, @password)
      end
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", read_timeout: 60) { |http| http.request(req) }
      request_id = res["X-Request-ID"].to_s
      raw = res.body.to_s
      code_i = res.code.to_i
      unless (200..299).cover?(code_i)
        message = raw.strip.empty? ? res.message : raw.strip
        code = ""
        begin
          parsed = JSON.parse(raw)
          message = parsed["error"] || message
          code = parsed["code"].to_s
          request_id = parsed["request_id"].to_s unless parsed["request_id"].to_s.empty?
        rescue JSON::ParserError
        end
        raise Error.new(message, code: code, status_code: code_i, request_id: request_id)
      end
      return {} if raw.empty?

      JSON.parse(raw)
    end
  end
end
