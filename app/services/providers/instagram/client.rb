module Providers
  module Instagram
    class Client < BaseClient
      AUTHORIZE_URL = "https://www.instagram.com/oauth/authorize"
      TOKEN_URL = "https://api.instagram.com/oauth/access_token"
      GRAPH_HOST = "https://graph.instagram.com"
      SCOPES = %w[
        instagram_business_basic
        instagram_business_content_publish
        instagram_business_manage_comments
        instagram_business_manage_messages
      ].freeze

      def authorization_url(state:, channel:)
        query = URI.encode_www_form(
          client_id: config.client_id,
          redirect_uri: callback_url,
          response_type: "code",
          scope: SCOPES.join(","),
          enable_fb_login: false,
          state:
        )
        "#{AUTHORIZE_URL}?#{query}"
      end

      def exchange_code(code:)
        short_lived = token_payload(post_form(TOKEN_URL, body: {
          client_id: config.client_id,
          client_secret: config.client_secret,
          grant_type: "authorization_code",
          redirect_uri: callback_url,
          code:
        }))
        long_lived = get("#{GRAPH_HOST}/access_token", params: {
          grant_type: "ig_exchange_token",
          client_secret: config.client_secret,
          access_token: short_lived.fetch("access_token")
        })

        TokenSet.new(
          access_token: long_lived.fetch("access_token"),
          refresh_token: nil,
          expires_at: expires_at(long_lived["expires_in"]),
          scopes: scopes(short_lived["permissions"]),
          provider_identity_id: short_lived.fetch("user_id").to_s,
          metadata: {}
        )
      end

      def discover_accounts(token_set:, channel:)
        payload = get(
          "#{GRAPH_HOST}/me",
          params: {fields: "user_id,username,name,account_type,profile_picture_url"},
          headers: {"Authorization" => "Bearer #{token_set.access_token}"}
        )
        account_id = (payload["user_id"] || payload.fetch("id")).to_s

        [AccountCandidate.new(
          provider_account_id: account_id,
          provider_identity_id: token_set.provider_identity_id,
          name: payload["name"].presence || payload["username"].presence || "Instagram account",
          handle: payload["username"],
          avatar_url: payload["profile_picture_url"],
          access_token: token_set.access_token,
          refresh_token: token_set.refresh_token,
          expires_at: token_set.expires_at,
          scopes: token_set.scopes,
          metadata: {"account_type" => payload["account_type"]}.compact
        )]
      end

      def refresh(token_set:)
        payload = get("#{GRAPH_HOST}/refresh_access_token", params: {
          grant_type: "ig_refresh_token",
          access_token: token_set.access_token
        })

        TokenSet.new(
          access_token: payload.fetch("access_token"),
          refresh_token: token_set.refresh_token,
          expires_at: expires_at(payload["expires_in"]),
          scopes: token_set.scopes,
          provider_identity_id: token_set.provider_identity_id,
          metadata: token_set.metadata
        )
      end

      private

      def token_payload(payload)
        data = payload["data"]
        return data.first if data.is_a?(Array) && data.first.is_a?(Hash)

        payload
      end
    end
  end
end
