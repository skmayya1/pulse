module Providers
  module Meta
    class Client < BaseClient
      def authorization_url(state:, channel:)
        scopes = %w[pages_show_list pages_read_engagement]
        scopes << "instagram_basic" if channel.key == "instagram"

        query = URI.encode_www_form(
          client_id: config.client_id,
          redirect_uri: callback_url,
          response_type: "code",
          scope: scopes.join(","),
          state:
        )
        "https://www.facebook.com/#{config.api_version}/dialog/oauth?#{query}"
      end

      def exchange_code(code:)
        payload = post_form(graph_url("oauth/access_token"), body: {
          client_id: config.client_id,
          client_secret: config.client_secret,
          redirect_uri: callback_url,
          code:
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
          fields: "id,name,access_token,picture{url},instagram_business_account{id,username,name,profile_picture_url}"
        }, headers: bearer_headers(token_set.access_token))

        Array(payload["data"]).filter_map do |page|
          (channel.key == "instagram") ? instagram_candidate(page, token_set) : facebook_candidate(page, token_set)
        end
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

      def instagram_candidate(page, token_set)
        account = page["instagram_business_account"]
        return unless account

        account_candidate(
          account:,
          token_set:,
          handle: account["username"],
          avatar_url: account["profile_picture_url"],
          access_token: page["access_token"],
          metadata: {"facebook_page_id" => page["id"]}
        )
      end

      def account_candidate(account:, token_set:, handle:, avatar_url:, access_token:, metadata: {})
        AccountCandidate.new(
          provider_account_id: account.fetch("id"),
          provider_identity_id: token_set.provider_identity_id,
          name: account["name"].presence || handle.presence || "Connected account",
          handle:,
          avatar_url:,
          access_token: access_token.presence || token_set.access_token,
          refresh_token: token_set.refresh_token,
          expires_at: token_set.expires_at,
          scopes: token_set.scopes,
          metadata:
        )
      end
    end
  end
end
