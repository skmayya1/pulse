class OrganizationsController < ApplicationController
  allow_organizationless_access only: [:new, :create]

  def new
    @organization = Organization.new(time_zone: "UTC")
    authorize @organization
  end

  def create
    @organization = Organization.new(organization_params.merge(time_zone: "UTC"))
    authorize @organization

    result = Organizations::CreateService.call(
      user: current_user,
      name: @organization.name,
      time_zone: @organization.time_zone
    )

    if result.success?
      redirect_to root_path, notice: "Organization created."
    else
      @organization.validate
      render :new, status: :unprocessable_content
    end
  end

  private

  def organization_params
    params.require(:organization).permit(:name)
  end
end
