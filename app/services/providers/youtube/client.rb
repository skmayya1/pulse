module Providers
  module Youtube
    class Client < BaseClient
      AUTHORIZE_URL = "https://accounts.google.com/o/oauth2/v2/auth"
      TOKEN_URL = "https://oauth2.googleapis.com/token"
      CHANNELS_URL = "https://www.googleapis.com/youtube/v3/channels"
      SCOPE = "https://www.googleapis.com/auth/youtube.readonly"

      def authorization_url(state:, channel:)
        query = URI.encode_www_form(
          client_id: config.client_id,
          redirect_uri: callback_url,
          response_type: "code",
          scope: SCOPE,
          access_type: "offline",
          include_granted_scopes: "true",
          prompt: "consent select_account",
          state:
        )
        "#{AUTHORIZE_URL}?#{query}"
      end

      def exchange_code(code:)
        payload = post_form(TOKEN_URL, body: {
          client_id: config.client_id,
          client_secret: config.client_secret,
          code:,
          grant_type: "authorization_code",
          redirect_uri: callback_url
        })

        token_set(payload)
      end

      def discover_accounts(token_set:, channel:)
        payload = get(
          CHANNELS_URL,
          params: {part: "snippet", mine: "true"},
          headers: {"Authorization" => "Bearer #{token_set.access_token}"}
        )

        Array(payload["items"]).map do |item|
          snippet = item["snippet"] || {}
          AccountCandidate.new(
            provider_account_id: item.fetch("id"),
            provider_identity_id: token_set.provider_identity_id,
            name: snippet["title"].presence || "YouTube channel",
            handle: snippet["customUrl"],
            avatar_url: snippet.dig("thumbnails", "default", "url"),
            access_token: token_set.access_token,
            refresh_token: token_set.refresh_token,
            expires_at: token_set.expires_at,
            scopes: token_set.scopes,
            metadata: {}
          )
        end
      end

      def refresh(token_set:)
        raise AuthorizationError, "Refresh token is unavailable" if token_set.refresh_token.blank?

        payload = post_form(TOKEN_URL, body: {
          client_id: config.client_id,
          client_secret: config.client_secret,
          grant_type: "refresh_token",
          refresh_token: token_set.refresh_token
        })

        self.token_set(payload, refresh_token: token_set.refresh_token, provider_identity_id: token_set.provider_identity_id)
      end

      private

      def token_set(payload, refresh_token: nil, provider_identity_id: nil)
        TokenSet.new(
          access_token: payload.fetch("access_token"),
          refresh_token: payload["refresh_token"] || refresh_token,
          expires_at: expires_at(payload["expires_in"]),
          scopes: scopes(payload["scope"].presence || SCOPE),
          provider_identity_id:,
          metadata: {}
        )
      end
    end
  end
end
