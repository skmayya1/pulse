class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user

  class << self
    def establish!(session)
      clear

      self.session = session
      self.user = session.user
    end

    def clear
      reset
    end
  end
end
