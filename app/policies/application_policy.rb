# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :context, :user, :record

  def initialize(context, record)
    @context = context
    @user = context.user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    def initialize(context, scope)
      @context = context
      @user = context.user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :context, :user, :scope
  end
end
