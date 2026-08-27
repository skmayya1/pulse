class MediaController < ApplicationController
  def index
    authorize library_media, :index?
    @query = params[:q].to_s
    return unless turbo_frame_request?

    search
    render partial: (params[:cursor].present? ? "media/page_frame" : "media/list_frame"),
      locals: {
        media_records: @media_records,
        next_cursor: @next_cursor,
        query: @query,
        time_zone: current_organization.time_zone
      }
  end

  def create
    authorize library_media, :create?
    result = CreateMediaBatchService.call(
      uploadable: current_organization,
      uploaded_by: current_user,
      files: Array(media_params[:files]).compact_blank,
      filename: media_params[:filename]
    )

    if result.success?
      notice = result.media_records.one? ? "Media uploaded." : "#{result.media_records.size} files uploaded."
      redirect_to media_index_path, notice:
    else
      @query = params[:q].to_s
      @media_form = result.media
      render :index, status: :unprocessable_content
    end
  end

  private

  def search
    result = MediaSearchQuery.new(
      scope: policy_scope(Media),
      uploadable: current_organization,
      query: params[:q],
      cursor: params[:cursor]
    ).call
    @media_records = result.records
    @next_cursor = result.next_cursor
    @query = params[:q].to_s
  end

  def library_media
    Media.new(uploadable: current_organization, uploaded_by: current_user)
  end

  def media_params
    params.fetch(:media, {}).permit(:filename, files: [])
  end
end
