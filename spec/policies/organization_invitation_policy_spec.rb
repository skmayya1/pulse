require "rails_helper"

RSpec.describe OrganizationInvitationPolicy do
  after { Current.clear }

  it "allows only the matching user to accept an active invitation" do
    invitation = create(:organization_invitation)
    invited_user = create(:user, email_address: invitation.email_address)

    expect(policy_for(invited_user, invitation)).to be_accept
    expect(policy_for(create(:user), invitation)).not_to be_accept

    invitation.update!(revoked_at: Time.current)
    expect(policy_for(invited_user, invitation)).not_to be_accept
  end

  it "denies members and users outside the organization" do
    organization = create(:organization)
    invitation = build(:organization_invitation, organization:)

    expect(policy_for(create_member(organization, :member), invitation)).not_to be_show
    expect(policy_for(create(:user), invitation)).not_to be_show
  end

  it "allows admins to manage member invitations only" do
    organization = create(:organization)
    admin = create_member(organization, :admin)

    expect(policy_for(admin, build(:organization_invitation, organization:, role: :member))).to be_create
    expect(policy_for(admin, build(:organization_invitation, organization:, role: :admin))).not_to be_create
    expect(policy_for(admin, create(:organization_invitation, organization:, role: :member))).to be_update
    expect(policy_for(admin, create(:organization_invitation, organization:, role: :admin))).not_to be_update
  end

  it "allows owners to manage admin and member invitations" do
    organization = create(:organization)
    owner = create_member(organization, :owner)
    invitation = create(:organization_invitation, organization:, role: :admin)
    policy = policy_for(owner, invitation)

    expect(policy).to be_show
    expect(policy).to be_create
    expect(policy).to be_update
    expect(policy).to be_destroy
  end

  it "scopes invitations to organizations administered by the user" do
    user = create(:user)
    included = create(:organization_invitation)
    excluded = create(:organization_invitation)
    create(:organization_membership, organization: included.organization, user:, role: :admin)
    Current.user = user

    result = described_class::Scope.new(Current, OrganizationInvitation).resolve

    expect(result).to include(included)
    expect(result).not_to include(excluded)
  end

  def create_member(organization, role)
    create(:organization_membership, organization:, role:).user
  end

  def policy_for(user, invitation)
    Current.user = user
    described_class.new(Current, invitation)
  end
end
