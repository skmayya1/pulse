module Providers
  class Configuration
    Config = Data.define(:client_id, :client_secret, :app_host, :api_version, :config_id) do
      def initialize(client_id:, client_secret:, app_host:, api_version: nil, config_id: nil)
        super
      end

      def configured?
        client_id.present? && client_secret.present? && app_host.present?
      end
    end

    class << self
      def for(provider)
        case provider.to_s
        when "instagram"
          Config.new(
            client_id: ENV["INSTAGRAM_CLIENT_ID"],
            client_secret: ENV["INSTAGRAM_CLIENT_SECRET"],
            app_host: ENV["APP_HOST"]
          )
        when "meta"
          Config.new(
            client_id: ENV["META_CLIENT_ID"],
            client_secret: ENV["META_CLIENT_SECRET"],
            app_host: ENV["APP_HOST"],
            api_version: ENV.fetch("META_API_VERSION", "v24.0"),
            config_id: ENV["META_CONFIG_ID"]
          )
        when "tiktok"
          Config.new(
            client_id: ENV["TIKTOK_CLIENT_KEY"],
            client_secret: ENV["TIKTOK_CLIENT_SECRET"],
            app_host: ENV["APP_HOST"]
          )
        when "youtube"
          Config.new(
            client_id: ENV["YOUTUBE_CLIENT_ID"],
            client_secret: ENV["YOUTUBE_CLIENT_SECRET"],
            app_host: ENV["APP_HOST"]
          )
        else
          raise ConfigurationError, "Unsupported provider"
        end
      end

      def configured?(provider)
        config = self.for(provider)
        return false unless config.configured?
        return config.config_id.present? if provider.to_s == "meta"

        true
      end
    end
  end
end
