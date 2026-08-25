class SettingsController < ApplicationController
  PAGES = {
    profile: {
      title: "Profile",
      description: "Manage your personal profile details."
    },
    preferences: {
      title: "Preferences",
      description: "Choose how Pulse works for you."
    },
    notifications: {
      title: "Notifications",
      description: "Control how Pulse notifies you."
    },
    organization_general: {
      title: "General",
      description: "Manage your organization details."
    },
    organization_channels: {
      title: "Channels",
      description: "Connect and manage your social channels."
    },
    organization_members: {
      title: "Members",
      description: "Manage organization members and invitations."
    }
  }.freeze

  def show
    authorize :settings, :show?
    redirect_to settings_profile_path
  end

  def profile
    prepare_page(:profile)
    @user = current_user
    authorize @user, :show?
  end

  def update_profile
    @user = current_user
    authorize @user, :update?

    if @user.update(profile_params)
      redirect_to settings_profile_path, notice: "Profile updated."
    else
      prepare_page(:profile)
      render :profile, status: :unprocessable_content
    end
  end

  def preferences
    prepare_page(:preferences)
    authorize :settings, :show?
  end

  def notifications
    render_page(:notifications)
  end

  def organization_general
    prepare_organization_general
    authorize @organization, :show?
  end

  def update_organization
    prepare_organization_general
    authorize @organization, :update?

    if @organization.update(organization_params)
      redirect_to settings_organization_general_path, notice: "Organization updated."
    else
      render :organization_general, status: :unprocessable_content
    end
  end

  def organization_channels
    prepare_page(:organization_channels)
    authorize :settings, :show?

    @channels = Channel.enabled.ordered
    prepare_connection_catalog
  end

  def organization_members
    prepare_page(:organization_members)
    authorize current_organization, :show?

    @memberships = organization_memberships
    prepare_invitations
  end

  private

  def render_page(page)
    prepare_page(page)
    authorize :settings, :show?
    render :show
  end

  def prepare_page(page)
    @page = PAGES.fetch(page).merge(key: page)
  end

  def prepare_organization_general
    prepare_page(:organization_general)
    @organization = current_organization
    @can_update_organization = policy(@organization).update?
  end

  def profile_params
    params.require(:user).permit(:name)
  end

  def organization_params
    params.require(:organization).permit(:name, :time_zone)
  end

  def prepare_connection_catalog
    connections = ProviderConnections::OrganizationQuery.new(
      scope: policy_scope(ProviderConnection),
      organization: current_organization
    )

    @connections_by_channel_id = connections.visible.includes(:channel).group_by(&:channel_id)
    @connection_counts = connections.active_counts
    @reauthorization_channel_ids = connections.reauthorization_channel_ids
    @configured_providers = Channel::PROVIDERS.index_with { Providers::Configuration.configured?(_1) }
    @can_manage_connections = current_organization_membership.role_at_least?(:admin)
  end

  def organization_memberships
    OrganizationMemberships::ListQuery.call(
      scope: policy_scope(OrganizationMembership),
      organization: current_organization
    )
  end

  def prepare_invitations
    invitation = OrganizationInvitation.new(
      organization: current_organization,
      invited_by: current_user,
      role: :member
    )
    @can_manage_invitations = policy(invitation).create?
    return unless @can_manage_invitations

    @invitations = OrganizationInvitations::PendingQuery.call(
      scope: policy_scope(OrganizationInvitation),
      organization: current_organization
    )
    @invitation_roles = current_organization_membership.owner? ? OrganizationInvitation.roles.keys : ["member"]
  end
end
