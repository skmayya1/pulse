module Providers
  class BaseClient
    CONNECT_TIMEOUT = 5
    READ_TIMEOUT = 10

    def initialize(config:, callback_url:, connection: nil)
      @config = config
      @callback_url = callback_url
      @connection = connection || Faraday.new do |faraday|
        faraday.options.open_timeout = CONNECT_TIMEOUT
        faraday.options.timeout = READ_TIMEOUT
      end

      raise ConfigurationError, "Provider is not configured" unless config.configured?
    end

    private

    attr_reader :config, :callback_url, :connection

    def get(url, params: {}, headers: {})
      request(:get, url, params:, headers:)
    end

    def post_form(url, body:)
      request(
        :post,
        url,
        body: URI.encode_www_form(body.compact),
        headers: {"Content-Type" => "application/x-www-form-urlencoded"}
      )
    end

    def request(method, url, params: {}, body: nil, headers: {})
      response = connection.run_request(method, url, body, headers) do |request|
        request.params.update(params.compact)
      end
      payload = parse_json(response.body)

      raise_response_error(response.status, payload) unless response.success?
      raise_payload_error(payload) if payload_error?(payload)

      payload
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => error
      raise TransientError, error.class.name
    end

    def parse_json(body)
      return {} if body.blank?
      return body if body.is_a?(Hash) || body.is_a?(Array)

      JSON.parse(body)
    rescue JSON::ParserError
      raise RequestError, "Provider returned an invalid response"
    end

    def raise_response_error(status, payload)
      error_class = (status == 429 || status >= 500) ? TransientError : AuthorizationError
      raise error_class, safe_error_message(payload)
    end

    def raise_payload_error(payload)
      raise AuthorizationError, safe_error_message(payload.fetch("error"))
    end

    def payload_error?(payload)
      return false unless payload.is_a?(Hash) && payload["error"].present?

      error = payload["error"]
      !error.is_a?(Hash) || error["code"].to_s != "ok"
    end

    def safe_error_message(payload)
      return "Provider request failed" unless payload.is_a?(Hash)

      payload["error_description"].presence || payload["message"].presence || "Provider request failed"
    end

    def expires_at(seconds)
      seconds.present? ? Time.current + seconds.to_i.seconds : nil
    end

    def scopes(value)
      Array(value.is_a?(String) ? value.split(/[\s,]+/) : value).compact_blank
    end
  end
end
