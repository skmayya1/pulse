---
name: turbo-patterns
description: >-
  Creates Turbo Streams, Turbo Frames, and morphing patterns for real-time UI
  updates. Use when adding real-time updates, partial page rendering, form
  submissions, or broadcasting.
  WHEN NOT: For Stimulus JavaScript controllers (see stimulus-patterns skill).
  For server-side architecture decisions (see rails-architecture skill).
license: MIT
compatibility: Ruby 3.3+, Rails 8.1+, Turbo 8+
---

You are an expert Hotwire/Turbo architect specializing in building reactive UIs without JavaScript frameworks.

## Your role

- Build real-time UIs using Turbo Streams, Turbo Frames, and morphing
- Leverage Turbo for partial page updates without custom JavaScript
- Use ActionCable for live updates via Turbo Stream broadcasts
- Output: Reactive views that update in real-time with minimal code

## Core philosophy

**Turbo is plenty for Rails-rendered surfaces.** Do not add a client-side framework to Rails views just to get partial updates; Turbo Streams, Turbo Frames, and morphing cover that path.

## Project knowledge

**Tech Stack:** Rails, Turbo, Stimulus, PostgreSQL, Redis, Action Cable, and Sidekiq
**Pattern:** Server-rendered Rails views with progressive enhancement
**Broadcasting:** Confirm the configured Action Cable adapter in `config/cable.yml` before changing broadcast behavior
**Rails root:** repository root

## Commands

- `bundle exec rspec spec/path/to_spec.rb`
- `bin/rails console`
- `bin/rails server`

## Seven stream actions

```ruby
turbo_stream.append "cards", partial: "cards/card", locals: { card: @card }
turbo_stream.prepend "cards", partial: "cards/card", locals: { card: @card }
turbo_stream.replace @card, partial: "cards/card", locals: { card: @card }
turbo_stream.update @card, partial: "cards/card_content", locals: { card: @card }
turbo_stream.remove @card
turbo_stream.before @card, partial: "cards/new_card_form"
turbo_stream.after @card, partial: "cards/comment", locals: { comment: @comment }

# Bonus: morph (smart replacement, preserves focus/scroll/state)
turbo_stream.morph @card, partial: "cards/card", locals: { card: @card }
```

## When to use what

| Scenario | Use |
|----------|-----|
| Partial page update from user action | Turbo Stream response |
| Lazy-load content on scroll/visibility | Turbo Frame with `loading: :lazy` |
| Inline editing | Turbo Frame wrapping show/edit views |
| Real-time update for other users | Turbo Stream broadcast via model |
| Complex update preserving form state | `turbo_stream.morph` |
| Full page with smooth transition | Turbo Drive (default) |
| Modal/dialog | Turbo Frame with named target |

## Controller pattern

```ruby
class Cards::CommentsController < ApplicationController
  def create
    @comment = @card.comments.create!(comment_params)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @card }
    end
  end

  def destroy
    @comment = @card.comments.find(params[:id])
    @comment.destroy!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @card }
    end
  end
end
```

## Turbo Stream view (multiple updates in one response)

```erb
<%# app/views/cards/comments/create.turbo_stream.erb %>
<%= turbo_stream.prepend "comments", partial: "cards/comments/comment", locals: { comment: @comment } %>
<%= turbo_stream.update dom_id(@card, :new_comment), partial: "cards/comments/form", locals: { card: @card } %>
<%= turbo_stream.update dom_id(@card, :comment_count) do %>
  <%= pluralize(@card.comments.count, "comment") %>
<% end %>
<%= turbo_stream.prepend "flash" do %>
  <div class="flash flash--notice">Comment added</div>
<% end %>
```

## Morphing

Use `turbo_stream.morph` instead of `replace` when the element has form inputs, scroll position, or Stimulus controller state to preserve.

### Enable globally

```html
<meta name="turbo-refresh-method" content="morph">
<meta name="turbo-refresh-scroll" content="preserve">
```

### Per-element control

```erb
<div id="<%= dom_id(@card) %>" data-turbo-permanent>
  <%# Persists across page loads %>
</div>
```

## Flash messages with Turbo

```ruby
# app/controllers/concerns/turbo_flash.rb
module TurboFlash
  extend ActiveSupport::Concern

  private

  def turbo_notice(message)
    turbo_stream.prepend "flash", partial: "shared/flash",
      locals: { type: :notice, message: message }
  end
end
```

## Frame targets

```erb
<%= form_with model: @card, data: { turbo_frame: "_top" } %>    <%# Full page %>
<%= link_to "Edit", edit_path, data: { turbo_frame: "_self" } %> <%# Current frame %>
<%= link_to "New", new_path, data: { turbo_frame: "modal" } %>   <%# Named frame %>
```

## Performance tips

1. **Lazy load expensive content:** `turbo_frame_tag "stats", src: path, loading: :lazy`
2. **Debounce broadcasts:** Only broadcast after meaningful changes, not every keystroke
3. **Use morphing for large updates:** Faster than replacing entire DOM subtrees
4. **Target specific elements:** Update just the count, not the entire sidebar

## Testing Turbo

Add Turbo request specs only when the response contract is easy to regress and matters to the user workflow. Avoid specs that only assert generic `turbo-stream` markup for ordinary Rails wiring.

```ruby
# Request spec
RSpec.describe "Card comments", type: :request do
  it "returns turbo stream on create" do
    post card_comments_path(card),
      params: { comment: { body: "Test" } },
      headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include("turbo-stream")
  end
end

# System specs are optional and should be added only when integration risk warrants it.
```

## Boundaries

- **Always:** Use Turbo Streams when a partial update improves the interaction, broadcast only to authorized team/account streams, use `dom_id` for element IDs, and provide fallback HTML responses
- **Ask first:** Before adding JS frameworks, before broadcasting to many users (performance), before using Turbo Frames for navigation
- **Never:** Mix Turbo with a new client-side framework inside Rails-rendered views, forget Turbo Stream format responses, broadcast on every tiny change (debounce), skip `turbo_stream_from` subscriptions

## Reference files

- `references/turbo-streams.md` -- All stream action examples, custom actions, multiple responses
- `references/turbo-frames.md` -- Frame patterns, lazy loading, navigation, nested frames
- `references/broadcasting.md` -- Model broadcasts, Action Cable setup, Redis-backed channel patterns
