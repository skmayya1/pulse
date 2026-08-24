module Providers
  module Tiktok
    class Client < BaseClient
      AUTHORIZE_URL = "https://www.tiktok.com/v2/auth/authorize/"
      TOKEN_URL = "https://open.tiktokapis.com/v2/oauth/token/"
      USER_URL = "https://open.tiktokapis.com/v2/user/info/"

      def authorization_url(state:, channel:)
        query = URI.encode_www_form(
          client_key: config.client_id,
          redirect_uri: callback_url,
          response_type: "code",
          scope: "user.info.basic",
          state:
        )
        "#{AUTHORIZE_URL}?#{query}"
      end

      def exchange_code(code:)
        payload = post_form(TOKEN_URL, body: {
          client_key: config.client_id,
          client_secret: config.client_secret,
          code:,
          grant_type: "authorization_code",
          redirect_uri: callback_url
        })

        token_set(payload)
      end

      def discover_accounts(token_set:, channel:)
        payload = get(
          USER_URL,
          params: {fields: "open_id,union_id,avatar_url,display_name"},
          headers: {"Authorization" => "Bearer #{token_set.access_token}"}
        )
        user = payload.dig("data", "user") || {}

        [AccountCandidate.new(
          provider_account_id: user.fetch("open_id"),
          provider_identity_id: user["union_id"].presence || user.fetch("open_id"),
          name: user["display_name"].presence || "TikTok account",
          handle: nil,
          avatar_url: user["avatar_url"],
          access_token: token_set.access_token,
          refresh_token: token_set.refresh_token,
          expires_at: token_set.expires_at,
          scopes: token_set.scopes,
          metadata: {}
        )]
      end

      def refresh(token_set:)
        raise AuthorizationError, "Refresh token is unavailable" if token_set.refresh_token.blank?

        payload = post_form(TOKEN_URL, body: {
          client_key: config.client_id,
          client_secret: config.client_secret,
          grant_type: "refresh_token",
          refresh_token: token_set.refresh_token
        })

        self.token_set(payload, provider_identity_id: token_set.provider_identity_id)
      end

      private

      def token_set(payload, provider_identity_id: nil)
        TokenSet.new(
          access_token: payload.fetch("access_token"),
          refresh_token: payload["refresh_token"],
          expires_at: expires_at(payload["expires_in"]),
          scopes: scopes(payload["scope"]),
          provider_identity_id: provider_identity_id || payload["open_id"],
          metadata: {"refresh_expires_in" => payload["refresh_expires_in"]}.compact
        )
      end
    end
  end
end
