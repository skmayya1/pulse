class OrganizationMembership < ApplicationRecord
  ROLE_LEVELS = {
    "member" => 0,
    "admin" => 1,
    "owner" => 2
  }.freeze

  belongs_to :organization
  belongs_to :user

  enum :role, {
    owner: "owner",
    admin: "admin",
    member: "member"
  }, validate: true

  validates :user_id, uniqueness: {scope: :organization_id}

  def role_at_least?(required_role)
    ROLE_LEVELS.fetch(role) >= ROLE_LEVELS.fetch(required_role.to_s)
  end
end
