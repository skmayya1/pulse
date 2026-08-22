module Authentication
  class ResolveUserService
    Result = Data.define(:user, :created, :error) do
      def success? = error.nil?
      def created? = created
    end

    def self.call(provider:, uid:, email_address:, name:)
      new(provider:, uid:, email_address:, name:).call
    end

    def initialize(provider:, uid:, email_address:, name:)
      @provider = provider.to_s
      @uid = uid.to_s.strip
      @email_address = email_address.to_s.strip.downcase
      @name = name.to_s.strip.presence
    end

    def call
      return failure(:invalid_user) unless valid_input?

      User.transaction(requires_new: true) do
        if provider == "google_oauth2"
          resolve_google_user
        else
          resolve_email_user
        end
      end
    rescue ActiveRecord::RecordNotUnique
      resolve_after_concurrent_write
    rescue ActiveRecord::RecordInvalid
      failure(:invalid_user)
    end

    private

    attr_reader :provider, :uid, :email_address, :name

    def valid_input?
      provider.in?(%w[email google_oauth2]) && uid.present? && email_address.match?(URI::MailTo::EMAIL_REGEXP)
    end

    def resolve_email_user
      user = find_user_by_email
      return Result.new(user:, created: false, error: nil) if user

      Result.new(
        user: User.create!(email_address:, verified_at: Time.current),
        created: true,
        error: nil
      )
    end

    def resolve_google_user
      google_user = User.lock.find_by(google_uid: uid)
      email_user = find_user_by_email

      return failure(:google_conflict) if google_user && email_user && google_user != email_user
      return Result.new(user: google_user, created: false, error: nil) if google_user
      return link_google_user(email_user) if email_user

      Result.new(
        user: User.create!(email_address:, google_uid: uid, name:, verified_at: Time.current),
        created: true,
        error: nil
      )
    end

    def link_google_user(user)
      return failure(:google_conflict) if user.google_uid.present? && user.google_uid != uid

      user.update!(google_uid: uid)
      Result.new(user:, created: false, error: nil)
    end

    def resolve_after_concurrent_write
      email_user = find_user_by_email
      return Result.new(user: email_user, created: false, error: nil) if provider == "email" && email_user
      return failure(:google_conflict) unless provider == "google_oauth2"

      google_user = User.find_by(google_uid: uid)
      return failure(:google_conflict) if google_user.blank? || (email_user && google_user != email_user)

      Result.new(user: google_user, created: false, error: nil)
    end

    def find_user_by_email
      User.lock.find_by("lower(email_address) = ?", email_address)
    end

    def failure(error)
      Result.new(user: nil, created: false, error:)
    end
  end
end
