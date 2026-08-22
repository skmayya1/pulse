module Organizations
  class CreateService
    Result = Data.define(:organization, :membership, :error) do
      def success? = error.nil?
    end

    def self.call(user:, name:, time_zone: "UTC")
      new(user:, name:, time_zone:).call
    end

    def initialize(user:, name:, time_zone:)
      @user = user
      @name = name
      @time_zone = time_zone
    end

    def call
      return failure unless user

      Organization.transaction do
        organization = Organization.create!(name:, time_zone:)
        membership = organization.organization_memberships.create!(user:, role: :owner)

        Result.new(organization:, membership:, error: nil)
      end
    rescue ActiveRecord::RecordInvalid
      failure
    end

    private

    attr_reader :user, :name, :time_zone

    def failure
      Result.new(organization: nil, membership: nil, error: :invalid)
    end
  end
end
