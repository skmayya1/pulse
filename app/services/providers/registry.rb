module Providers
  class Registry
    CLIENTS = {
      "meta" => Providers::Meta::Client,
      "tiktok" => Providers::Tiktok::Client,
      "youtube" => Providers::Youtube::Client
    }.freeze

    class << self
      def for(provider, connection: nil)
        provider = provider.to_s
        client_class = CLIENTS.fetch(provider) { raise ConfigurationError, "Unsupported provider" }
        config = Configuration.for(provider)

        client_class.new(
          config:,
          callback_url: callback_url(provider, config.app_host),
          connection:
        )
      end

      private

      def callback_url(provider, app_host)
        path = Rails.application.routes.url_helpers.provider_connection_oauth_callback_path(provider:)
        URI.join(app_host.to_s.end_with?("/") ? app_host.to_s : "#{app_host}/", path.delete_prefix("/")).to_s
      rescue URI::InvalidURIError
        raise ConfigurationError, "APP_HOST is invalid"
      end
    end
  end
end
