class HomeController < ApplicationController
  def index
    @organizations = policy_scope(Organization).order(:name)
  end
end
