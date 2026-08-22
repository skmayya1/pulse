class OrganizationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    organization_member?
  end

  def create?
    user.present?
  end

  def update?
    organization_admin?
  end

  def destroy?
    organization_owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      scope.joins(:organization_memberships)
        .where(organization_memberships: {user_id: user.id})
        .distinct
    end
  end
end
