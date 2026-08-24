module OrganizationContext
  extend ActiveSupport::Concern

  included do
    helper_method :current_organization, :current_organization_membership
  end

  def current_organization
    return unless current_user

    @current_organization ||= current_user.organizations.sole
  end

  def current_organization_membership
    return unless current_organization

    @current_organization_membership ||= current_user.organization_memberships.find_by!(
      organization: current_organization
    )
  end
end
