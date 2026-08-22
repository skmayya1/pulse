require "rails_helper"

RSpec.describe ApplicationController do
  after { Current.clear }

  it "exposes request-scoped authentication helpers to controllers and views" do
    user = create(:user)
    session = create(:session, user:)
    Current.establish!(session)
    controller = described_class.new

    expect(controller.current_session).to eq(session)
    expect(controller.current_user).to eq(user)
    expect(controller).to be_signed_in
    expect(controller.pundit_user).to eq(Current)
    expect(described_class._helper_methods).to include(
      :current_session,
      :current_user,
      :signed_in?
    )
  end
end
