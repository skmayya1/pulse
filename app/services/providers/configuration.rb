module Providers
  class Configuration
    Config = Data.define(:client_id, :client_secret, :app_host, :api_version) do
      def configured?
        client_id.present? && client_secret.present? && app_host.present?
      end
    end

    class << self
      def for(provider)
        case provider.to_s
        when "meta"
          Config.new(
            client_id: ENV["META_CLIENT_ID"],
            client_secret: ENV["META_CLIENT_SECRET"],
            app_host: ENV["APP_HOST"],
            api_version: ENV.fetch("META_API_VERSION", "v24.0")
          )
        when "tiktok"
          Config.new(
            client_id: ENV["TIKTOK_CLIENT_KEY"],
            client_secret: ENV["TIKTOK_CLIENT_SECRET"],
            app_host: ENV["APP_HOST"],
            api_version: nil
          )
        when "youtube"
          Config.new(
            client_id: ENV["YOUTUBE_CLIENT_ID"],
            client_secret: ENV["YOUTUBE_CLIENT_SECRET"],
            app_host: ENV["APP_HOST"],
            api_version: nil
          )
        else
          raise ConfigurationError, "Unsupported provider"
        end
      end

      def configured?(provider)
        self.for(provider).configured?
      end
    end
  end
end
