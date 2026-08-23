class ProviderConnectionPolicy < ApplicationPolicy
  def index?
    organization_member?
  end

  def show?
    organization_member?
  end

  def create?
    organization_admin?
  end

  def update?
    organization_admin?
  end

  def destroy?
    organization_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      scope.where(organization_id: user.organization_memberships.select(:organization_id))
    end
  end
end
