class CreateMediaService
  Result = Data.define(:media, :error) do
    def success? = error.nil?
  end

  def self.call(uploadable:, uploaded_by:, file:, filename: nil)
    new(uploadable:, uploaded_by:, file:, filename:).call
  end

  def initialize(uploadable:, uploaded_by:, file:, filename:)
    @uploadable = uploadable
    @uploaded_by = uploaded_by
    @file = file
    @filename = filename.to_s.strip.presence
  end

  def call
    media = Media.new(uploadable:, uploaded_by:, kind:)
    media.filename = filename if filename
    media.file.attach(file) if file.present?

    if media.save
      Result.new(media:, error: nil)
    else
      Result.new(media:, error: :invalid)
    end
  end

  private

  attr_reader :uploadable, :uploaded_by, :file, :filename

  def kind
    content_type = file.respond_to?(:content_type) ? file.content_type : nil
    return :video if Media::VIDEO_CONTENT_TYPES.include?(content_type)

    :image
  end
end
