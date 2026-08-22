module OrganizationAccess
  extend ActiveSupport::Concern

  included do
    before_action :require_organization_access
  end

  class_methods do
    def allow_organizationless_access(**options)
      skip_before_action :require_organization_access, **options
    end
  end

  private

  def require_organization_access
    return if current_user.blank?
    return if current_user.organization_memberships.exists?

    redirect_to new_organization_path
  end
end
