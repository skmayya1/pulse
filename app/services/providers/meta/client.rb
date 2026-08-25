module Providers
  module Meta
    class Client < BaseClient
      def initialize(config:, callback_url:, connection: nil)
        super
        raise ConfigurationError, "Provider is not configured" if config.config_id.blank?
      end

      def authorization_url(state:, channel:)
        query = URI.encode_www_form(
          client_id: config.client_id,
          redirect_uri: callback_url,
          response_type: "code",
          config_id: config.config_id,
          state:
        )
        "https://www.facebook.com/#{config.api_version}/dialog/oauth?#{query}"
      end

      def exchange_code(code:)
        short_lived = post_form(graph_url("oauth/access_token"), body: {
          client_id: config.client_id,
          client_secret: config.client_secret,
          redirect_uri: callback_url,
          code:
        })
        payload = post_form(graph_url("oauth/access_token"), body: {
          grant_type: "fb_exchange_token",
          client_id: config.client_id,
          client_secret: config.client_secret,
          fb_exchange_token: short_lived.fetch("access_token")
        })
        identity = get(
          graph_url("me"),
          params: {fields: "id"},
          headers: bearer_headers(payload.fetch("access_token"))
        )

        token_set(payload, provider_identity_id: identity.fetch("id"))
      end

      def discover_accounts(token_set:, channel:)
        payload = get(graph_url("me/accounts"), params: {
          fields: "id,name,access_token,picture{url}"
        }, headers: bearer_headers(token_set.access_token))

        Array(payload["data"]).map { |page| facebook_candidate(page, token_set) }
      end

      def refresh(token_set:)
        payload = post_form(graph_url("oauth/access_token"), body: {
          grant_type: "fb_exchange_token",
          client_id: config.client_id,
          client_secret: config.client_secret,
          fb_exchange_token: token_set.access_token
        })

        token_set(payload, provider_identity_id: token_set.provider_identity_id, refresh_token: token_set.refresh_token)
      end

      private

      def graph_url(path)
        "https://graph.facebook.com/#{config.api_version}/#{path}"
      end

      def bearer_headers(access_token)
        {"Authorization" => "Bearer #{access_token}"}
      end

      def token_set(payload, provider_identity_id:, refresh_token: nil)
        TokenSet.new(
          access_token: payload.fetch("access_token"),
          refresh_token: payload["refresh_token"] || refresh_token,
          expires_at: expires_at(payload["expires_in"]),
          scopes: scopes(payload["scope"]),
          provider_identity_id:,
          metadata: {}
        )
      end

      def facebook_candidate(page, token_set)
        account_candidate(
          account: page,
          token_set:,
          handle: nil,
          avatar_url: page.dig("picture", "data", "url"),
          access_token: page["access_token"]
        )
      end

      def account_candidate(account:, token_set:, handle:, avatar_url:, access_token:)
        AccountCandidate.new(
          provider_account_id: account.fetch("id"),
          provider_identity_id: token_set.provider_identity_id,
          name: account["name"].presence || handle.presence || "Connected account",
          handle:,
          avatar_url:,
          access_token: access_token.presence || token_set.access_token,
          refresh_token: token_set.refresh_token,
          expires_at: nil,
          scopes: token_set.scopes,
          metadata: {}
        )
      end
    end
  end
end
