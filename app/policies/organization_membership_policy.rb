class OrganizationMembershipPolicy < ApplicationPolicy
  def index?
    organization_member?
  end

  def show?
    organization_member?
  end

  def create?
    return false unless organization_admin?
    return record.member? if organization_membership.admin?

    !record.owner?
  end

  def update?
    organization_owner? && !record.owner?
  end

  def destroy?
    return false unless organization_admin?
    return record.member? if organization_membership.admin?

    !record.owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      scope.where(organization_id: user.organization_memberships.select(:organization_id))
    end
  end
end
