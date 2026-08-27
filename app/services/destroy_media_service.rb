class DestroyMediaService
  Result = Data.define(:media, :error) do
    def success? = error.nil?
  end

  def self.call(media:)
    new(media:).call
  end

  def initialize(media:)
    @media = media
  end

  def call
    if media.destroy
      Result.new(media:, error: nil)
    else
      Result.new(media:, error: :in_use)
    end
  end

  private

  attr_reader :media
end
