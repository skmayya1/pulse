module Authentication
  class OtpService
    CODE_LIFETIME = 10.minutes
    RESEND_COOLDOWN = 60.seconds
    RATE_LIMIT_WINDOW = 1.hour
    MAX_SENDS = 5
    MAX_ATTEMPTS = 5
    LOCK_LIFETIME = 5.seconds

    Result = Data.define(:sent, :error) do
      def success? = error.nil?
      def sent? = sent
    end

    class << self
      def send_code(email_address:, ip_address:)
        new(email_address:, ip_address:).send_code
      end

      def verify_code(email_address:, code:, ip_address:)
        new(email_address:, ip_address:).verify_code(code.to_s)
      end
    end

    def initialize(email_address:, ip_address:)
      @email_address = email_address.to_s.strip.downcase
      @ip_address = ip_address.to_s.presence || "unknown"
    end

    def send_code
      return failure(:invalid_email) unless valid_email?
      return Result.new(sent: true, error: nil) if configured_code

      with_lock do
        next failure(:cooldown) if Rails.cache.exist?(cooldown_key)
        next failure(:rate_limited) unless within_send_limits?

        code = configured_code || format("%06d", SecureRandom.random_number(1_000_000))
        Rails.cache.write(
          challenge_key,
          {digest: digest(code), attempts: 0, expires_at: CODE_LIFETIME.from_now},
          expires_in: CODE_LIFETIME
        )
        Rails.cache.write(cooldown_key, true, expires_in: RESEND_COOLDOWN)

        Result.new(sent: true, error: nil)
      end
    end

    def verify_code(code)
      return failure(:invalid_code) unless code.match?(/\A\d{6}\z/)
      return fixed_code_result(code) if configured_code

      with_lock do
        challenge = Rails.cache.read(challenge_key)
        next failure(:invalid_code) unless challenge

        if challenge.fetch(:expires_at) <= Time.current
          Rails.cache.delete(challenge_key)
          next failure(:expired)
        end

        if secure_match?(challenge.fetch(:digest), digest(code))
          Rails.cache.delete(challenge_key)
          next Result.new(sent: false, error: nil)
        end

        challenge[:attempts] += 1
        if challenge.fetch(:attempts) >= MAX_ATTEMPTS
          Rails.cache.delete(challenge_key)
        else
          Rails.cache.write(challenge_key, challenge, expires_in: challenge.fetch(:expires_at) - Time.current)
        end

        failure(:invalid_code)
      end
    end

    private

    attr_reader :email_address, :ip_address

    def valid_email?
      email_address.match?(URI::MailTo::EMAIL_REGEXP)
    end

    def configured_code
      code = Rails.application.config.x.authentication.development_otp_code.presence
      return unless code
      raise ArgumentError, "DEVELOPMENT_OTP_CODE must contain exactly six digits" unless code.match?(/\A\d{6}\z/)

      code
    end

    def fixed_code_result(code)
      if secure_match?(digest(configured_code), digest(code))
        Result.new(sent: false, error: nil)
      else
        failure(:invalid_code)
      end
    end

    def within_send_limits?
      email_count = increment_counter(rate_key("email", email_address))
      ip_count = increment_counter(rate_key("ip", ip_address))
      email_count <= MAX_SENDS && ip_count <= MAX_SENDS
    end

    def increment_counter(key)
      Rails.cache.write(key, 0, expires_in: RATE_LIMIT_WINDOW, unless_exist: true)
      Rails.cache.increment(key, 1, expires_in: RATE_LIMIT_WINDOW)
    end

    def with_lock
      token = SecureRandom.uuid
      acquired = Rails.cache.write(lock_key, token, expires_in: LOCK_LIFETIME, unless_exist: true)
      return failure(:busy) unless acquired

      yield
    ensure
      Rails.cache.delete(lock_key) if token && Rails.cache.read(lock_key) == token
    end

    def secure_match?(stored_digest, candidate_digest)
      ActiveSupport::SecurityUtils.secure_compare(stored_digest, candidate_digest)
    end

    def digest(code)
      OpenSSL::HMAC.hexdigest("SHA256", hmac_key, code)
    end

    def hmac_key
      Rails.application.key_generator.generate_key("pulse-email-otp-digest", 32)
    end

    def challenge_key
      "authentication:otp:challenge:#{identifier_digest(email_address)}"
    end

    def cooldown_key
      "authentication:otp:cooldown:#{identifier_digest(email_address)}"
    end

    def lock_key
      "authentication:otp:lock:#{identifier_digest(email_address)}"
    end

    def rate_key(kind, value)
      "authentication:otp:rate:#{kind}:#{identifier_digest(value)}"
    end

    def identifier_digest(value)
      Digest::SHA256.hexdigest("email:#{value}")
    end

    def failure(error)
      Result.new(sent: false, error:)
    end
  end
end
