module Providers
  TokenSet = Data.define(
    :access_token,
    :refresh_token,
    :expires_at,
    :scopes,
    :provider_identity_id,
    :metadata
  )
end
