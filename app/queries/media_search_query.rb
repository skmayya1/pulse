class MediaSearchQuery
  PAGE_SIZE = 20
  Result = Data.define(:records, :next_cursor)

  def initialize(scope:, uploadable:, query: nil, cursor: nil, limit: PAGE_SIZE)
    @scope = scope.where(uploadable:)
    @query = query.to_s.strip.presence
    @cursor = cursor
    @limit = limit
  end

  def self.encode(record)
    Base64.urlsafe_encode64("#{record.created_at.utc.iso8601(6)}/#{record.id}", padding: false)
  end

  def call
    records = filtered.order(created_at: :desc, id: :desc).limit(limit + 1).to_a
    next_cursor = nil
    if records.size > limit
      records = records.first(limit)
      next_cursor = self.class.encode(records.last)
    end

    Result.new(records:, next_cursor:)
  end

  private

  attr_reader :scope, :query, :cursor, :limit

  def filtered
    relation = scope.with_attached_file.includes(:uploaded_by)
    relation = relation.where("filename ILIKE ?", "%#{Media.sanitize_sql_like(query)}%") if query
    apply_cursor(relation)
  end

  def apply_cursor(relation)
    created_at, id = decoded_cursor
    return relation unless created_at && id

    relation.where("(created_at, id) < (?, ?)", created_at, id)
  end

  def decoded_cursor
    return if cursor.blank?

    timestamp, id = Base64.urlsafe_decode64(cursor).split("/", 2)
    [Time.iso8601(timestamp), Integer(id)]
  rescue ArgumentError, TypeError
    nil
  end
end
