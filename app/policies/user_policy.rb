class UserPolicy < ApplicationPolicy
  def show?
    user.present? && record == user
  end

  def update?
    show?
  end
end
