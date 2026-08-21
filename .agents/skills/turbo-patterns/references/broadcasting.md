# Broadcasting Reference

## Model broadcasting with concerns

```ruby
# app/models/card/broadcastable.rb
module Card::Broadcastable
  extend ActiveSupport::Concern

  included do
    after_create_commit :broadcast_creation
    after_update_commit :broadcast_update
    after_destroy_commit :broadcast_removal
  end

  private

  def broadcast_creation
    broadcast_prepend_to board, :cards,
      target: "cards",
      partial: "cards/card",
      locals: { card: self }
  end

  def broadcast_update
    broadcast_replace_to board,
      target: self,
      partial: "cards/card",
      locals: { card: self }
  end

  def broadcast_removal
    broadcast_remove_to board, target: self
  end
end
```

## View subscription

```erb
<%# app/views/boards/show.html.erb %>

<%# Subscribe to board's card stream %>
<%= turbo_stream_from @board, :cards %>

<div id="cards">
  <%= render @board.cards %>
</div>
```

The `turbo_stream_from` helper creates a WebSocket subscription via ActionCable.

## Multiple stream subscriptions

```erb
<%# Subscribe to different streams on the same page %>
<%= turbo_stream_from @card %>
<%= turbo_stream_from @card, :activity %>
<%= turbo_stream_from current_user, :notifications %>

<div class="card-container">
  <%= render "cards/container", card: @card %>

  <div id="<%= dom_id(@card, :activity) %>">
    <%= render "cards/activity", card: @card %>
  </div>
end
```

## Broadcasting to multiple streams

```ruby
class Comment < ApplicationRecord
  after_create_commit :broadcast_to_streams

  private

  def broadcast_to_streams
    # Broadcast to card's comment list
    broadcast_prepend_to card, :comments,
      target: dom_id(card, :comments),
      partial: "cards/comments/comment"

    # Broadcast to card's activity feed
    broadcast_prepend_to card, :activity,
      target: dom_id(card, :activity),
      partial: "cards/activity/comment_created",
      locals: { comment: self }

    # Notify each watcher
    card.watchers.each do |watcher|
      broadcast_prepend_to watcher, :notifications,
        target: "notifications",
        partial: "notifications/comment_notification",
        locals: { comment: self, user: watcher }
    end
  end
end
```

## Manual broadcasting (from controllers, services, jobs)

```ruby
# Broadcast to all board viewers
Turbo::StreamsChannel.broadcast_append_to(
  @board, :cards,
  target: "cards",
  partial: "cards/card",
  locals: { card: @card }
)

# Broadcast to specific user
Turbo::StreamsChannel.broadcast_replace_to(
  "user_#{@user.id}",
  target: dom_id(@notification),
  partial: "notifications/notification",
  locals: { notification: @notification }
)

# Broadcast a page refresh (morphing)
Turbo::StreamsChannel.broadcast_refresh_to(@board)
```

## Page refresh broadcasts

Trigger a full-page morph for all subscribers:

```ruby
# After background job completes
def after_import
  Turbo::StreamsChannel.broadcast_refresh_to(@board)
end

# Conditional refresh for specific users
def notify_status_change
  @card.watchers.each do |watcher|
    Turbo::StreamsChannel.broadcast_refresh_to("user_#{watcher.id}")
  end
end
```

Requires morph meta tags in layout:

```html
<meta name="turbo-refresh-method" content="morph">
<meta name="turbo-refresh-scroll" content="preserve">
```

## Pulse Action Cable configuration

Before changing broadcasts, inspect `config/cable.yml` and the deployment configuration. Subscribe only to streams scoped to the authorized team/account; never use a shared stream name for private conversation, account, or approval data.

Redis is available for Sidekiq and may also back Action Cable, but do not assume the adapter or channel prefix—follow the repository configuration.

## Drag and drop with broadcasting

```ruby
# app/controllers/boards/columns/reorders_controller.rb
class Boards::Columns::ReordersController < ApplicationController
  def update
    column = @board.columns.find(params[:id])
    column.insert_at(params[:position].to_i + 1)
    head :no_content
    # Model callbacks handle broadcasting the new order
  end
end
```

## Testing broadcasts

```ruby
# Request/model specs are preferred. Add system specs only for real UI integration risk.
RSpec.describe Card, type: :model do
  include ActionCable::TestHelper

  it "broadcasts creation after commit" do
    expect {
      create(:card, board: board)
    }.to have_broadcasted_to([board, :cards])
  end
end
```
