class MediaPolicy < ApplicationPolicy
  def index?
    uploadable_member?
  end

  def create?
    uploadable_member?
  end

  def destroy?
    return false unless uploadable_member?

    record.uploaded_by_id == user.id || organization_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      organization_ids = user.organization_memberships.select(:organization_id)
      scope.where(uploadable_type: "Organization", uploadable_id: organization_ids)
        .or(scope.where(uploadable_type: "User", uploadable_id: user.id))
    end
  end

  private

  def organization
    uploadable if uploadable.is_a?(Organization)
  end

  def uploadable
    record.uploadable
  end

  def uploadable_member?
    return record == user if uploadable.is_a?(User)

    organization_member?
  end
end
