module ProviderConnections
  class OauthFlowStore
    AUTHORIZATION_TTL = 10.minutes
    SELECTION_TTL = 10.minutes

    class RedisBackend
      def initialize(url:)
        @redis = Redis.new(url:)
      end

      def write(key, value, expires_in:)
        @redis.set(key, value, ex: expires_in.to_i, nx: true)
      end

      def read(key)
        @redis.get(key)
      end

      def consume(key)
        @redis.getdel(key)
      end
    end

    class CacheBackend
      MUTEX = Mutex.new

      def initialize(cache: Rails.cache)
        @cache = cache
      end

      def write(key, value, expires_in:)
        @cache.write(key, value, expires_in:, unless_exist: true)
      end

      def read(key)
        @cache.read(key)
      end

      def consume(key)
        MUTEX.synchronize do
          value = @cache.read(key)
          @cache.delete(key)
          value
        end
      end
    end

    def initialize(backend: default_backend, encryptor: default_encryptor)
      @backend = backend
      @encryptor = encryptor
    end

    def issue_authorization(user_id:, organization_id:, channel_id:)
      issue(
        "authorization",
        {"user_id" => user_id, "organization_id" => organization_id, "channel_id" => channel_id},
        expires_in: AUTHORIZATION_TTL
      )
    end

    def consume_authorization(token)
      consume("authorization", token)
    end

    def issue_selection(payload)
      issue("selection", payload, expires_in: SELECTION_TTL)
    end

    def read_selection(token)
      read("selection", token)
    end

    def consume_selection(token)
      consume("selection", token)
    end

    private

    attr_reader :backend, :encryptor

    def issue(namespace, payload, expires_in:)
      loop do
        token = SecureRandom.urlsafe_base64(32)
        return token if backend.write(key(namespace, token), encryptor.encrypt_and_sign(payload), expires_in:)
      end
    end

    def read(namespace, token)
      decrypt(backend.read(key(namespace, token)))
    end

    def consume(namespace, token)
      decrypt(backend.consume(key(namespace, token)))
    end

    def decrypt(value)
      return if value.blank?

      encryptor.decrypt_and_verify(value)
    rescue ActiveSupport::MessageEncryptor::InvalidMessage
      nil
    end

    def key(namespace, token)
      digest = Digest::SHA256.hexdigest(token.to_s)
      "provider_connections:oauth:#{namespace}:#{digest}"
    end

    def default_backend
      if Rails.env.test?
        CacheBackend.new
      else
        RedisBackend.new(url: Rails.application.config.x.cache_redis_url)
      end
    end

    def default_encryptor
      key = Rails.application.key_generator.generate_key("provider-connections/oauth-flow", 32)
      ActiveSupport::MessageEncryptor.new(key, cipher: "aes-256-gcm", serializer: JSON)
    end
  end
end
