class CreateMediaBatchService
  Result = Data.define(:media_records, :media, :error) do
    def success? = error.nil?
  end

  def self.call(uploadable:, uploaded_by:, files:, filename: nil)
    new(uploadable:, uploaded_by:, files:, filename:).call
  end

  def initialize(uploadable:, uploaded_by:, files:, filename:)
    @uploadable = uploadable
    @uploaded_by = uploaded_by
    @files = Array(files).compact_blank
    @filename = filename
  end

  def call
    return failure(:blank, "can't be blank") if files.empty?
    return failure(:too_many, "is limited to #{Media::MAX_BATCH} at a time") if files.size > Media::MAX_BATCH

    failed = nil
    records = []

    Media.transaction do
      files.each do |file|
        result = CreateMediaService.call(
          uploadable:,
          uploaded_by:,
          file:,
          filename: files.one? ? filename : nil
        )
        unless result.success?
          failed = result.media
          raise ActiveRecord::Rollback
        end

        records << result.media
      end
    end

    return failure(:invalid, media: failed) if failed

    Result.new(media_records: records, media: records.last, error: nil)
  end

  private

  attr_reader :uploadable, :uploaded_by, :files, :filename

  def failure(error, message = nil, media: nil)
    media ||= Media.new(uploadable:, uploaded_by:)
    media.errors.add(:file, message) if message
    Result.new(media_records: [], media:, error:)
  end
end
