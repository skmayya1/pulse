class SettingsController < ApplicationController
  PAGES = {
    overview: {
      title: "Settings",
      description: "Manage your personal profile and organization workspace."
    },
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
    render_page(:overview)
  end

  def profile
    render_page(:profile)
  end

  def preferences
    render_page(:preferences)
  end

  def notifications
    render_page(:notifications)
  end

  def organization_general
    prepare_page(:organization_general)
    @organization = current_organization
    authorize @organization, :show?
    @can_update_organization = policy(@organization).update?
    render :organization_general
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
