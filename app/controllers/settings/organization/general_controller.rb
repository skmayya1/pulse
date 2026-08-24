module Settings
  module Organization
    class GeneralController < ApplicationController
      def update
        @organization = current_organization
        authorize @organization

        if @organization.update(organization_params)
          redirect_to settings_organization_general_path, notice: "Organization updated."
        else
          @page = SettingsController::PAGES.fetch(:organization_general).merge(key: :organization_general)
          @can_update_organization = true
          render "settings/organization_general", status: :unprocessable_content
        end
      end

      private

      def organization_params
        params.require(:organization).permit(:name, :time_zone)
      end
    end
  end
end
