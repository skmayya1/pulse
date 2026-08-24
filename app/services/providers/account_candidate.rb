module Providers
  AccountCandidate = Data.define(
    :provider_account_id,
    :provider_identity_id,
    :name,
    :handle,
    :avatar_url,
    :access_token,
    :refresh_token,
    :expires_at,
    :scopes,
    :metadata
  )
end
