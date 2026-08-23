class SettingsPolicy < ApplicationPolicy
  def show?
    user.present?
  end
end
