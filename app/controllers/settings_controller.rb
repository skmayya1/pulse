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
    render_page(:organization_general)
  end

  def organization_channels
    render_page(:organization_channels)
  end

  def organization_members
    @page = PAGES.fetch(:organization_members).merge(key: :organization_members)
    @organization = current_user.organizations.sole
    @organization_membership = current_user.organization_memberships.find_by!(organization: @organization)
    authorize @organization, :show?

    @memberships = policy_scope(OrganizationMembership)
      .where(organization: @organization)
      .includes(:user)
      .order(:created_at)
    @can_manage_invitations = policy(OrganizationInvitation.new(organization: @organization, invited_by: current_user, role: :member)).create?
    @invitations = pending_invitations if @can_manage_invitations
    @invitation_roles = @organization_membership.owner? ? OrganizationInvitation.roles.keys : ["member"]

    render :organization_members
  end

  private

  def render_page(page)
    @page = PAGES.fetch(page).merge(key: page)
    authorize :settings, :show?
    render :show
  end

  def pending_invitations
    policy_scope(OrganizationInvitation)
      .where(organization: @organization)
      .pending
      .includes(:invited_by)
      .order(created_at: :desc)
  end
end
