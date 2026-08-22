class OrganizationInvitationPolicy < ApplicationPolicy
  def accept?
    user.present? &&
      record.email_address == user.email_address &&
      record.class.pending.exists?(id: record.id)
  end

  def index?
    organization_admin?
  end

  def show?
    organization_admin?
  end

  def create?
    return false unless organization_admin?
    return record.member? if organization_membership.admin?

    true
  end

  def update?
    organization_owner? || (organization_admin? && record.member?)
  end

  def destroy?
    organization_owner? || (organization_admin? && record.member?)
  end

  alias_method :resend?, :update?
  alias_method :revoke?, :destroy?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      managed_organization_ids = user.organization_memberships
        .where(role: %w[owner admin])
        .select(:organization_id)

      scope.where(organization_id: managed_organization_ids)
    end
  end
end
