# Partial Patterns

Read this reference when creating or substantially refactoring a Rails partial.
Use the smallest pattern that keeps the caller and partial easy to understand.

## Explicit strict locals

Action templates may receive controller instance variables. Convert them into
an explicit partial API at the render boundary.

```erb
<%# app/views/posts/show.html.erb %>
<%= render "posts/post", post: @post, compact: false %>
```

```erb
<%# app/views/posts/_post.html.erb %>
<%# locals: (post:, compact: false) %>

<article id="<%= dom_id(post) %>" class="card border border-base-300 bg-base-100">
  <div class="card-body">
    <h2 class="card-title"><%= post.title %></h2>
    <% unless compact %>
      <p class="text-base-content/70"><%= post.summary %></p>
    <% end %>
  </div>
</article>
```

Required data has no default. Optional presentation state has a clear default.
Do not replace this with `@post` inside the partial. Use `local_assigns` only
when maintaining an older dynamic partial that cannot yet adopt strict locals.

## Canonical resource and collection rendering

Name a resource's default representation after the resource:

```text
app/views/posts/_post.html.erb
```

Rails then supplies the `post` local automatically:

```erb
<%= render @post %>
<%= render @posts %>
```

When additional locals are necessary, be explicit:

```erb
<%= render partial: "posts/post", collection: @posts, locals: { compact: true } %>
```

Keep collection structure and empty state at the page level:

```erb
<div class="grid gap-4 md:grid-cols-2" id="posts">
  <% if @posts.any? %>
    <%= render @posts %>
  <% else %>
    <%= render "application/empty_state",
      title: "No posts yet",
      description: "Create a post to start planning content." %>
  <% end %>
</div>
```

## Shared forms

Share new/edit form markup by passing the model explicitly. Pass supporting
collections or options as separate required locals instead of querying inside
the form partial.

```erb
<%= render "form", post: @post, social_accounts: @social_accounts %>
```

```erb
<%# locals: (post:, social_accounts:) %>

<%= form_with model: post, class: "space-y-6" do |form| %>
  <fieldset class="fieldset">
    <%= form.label :caption, class: "fieldset-legend" %>
    <%= form.text_area :caption, class: "textarea textarea-bordered w-full" %>
  </fieldset>

  <%= form.submit class: "btn btn-primary" %>
<% end %>
```

The action template owns `@post`; the partial owns only its declared `post`
local. Validation and authorization remain outside the partial.

## Conditional daisyUI variants

Prefer semantic variants and `class_names` for small visual differences:

```erb
<%# locals: (label:, tone: :neutral) %>
<% tone_class = {
  neutral: "badge-neutral",
  success: "badge-success",
  warning: "badge-warning",
  error: "badge-error"
}.fetch(tone) %>

<span class="<%= class_names("badge", tone_class) %>"><%= label %></span>
```

The caller should decide the semantic state. If this mapping becomes broadly
reused or the variants acquire behavior, move it to a helper, presenter, or
ViewComponent rather than duplicating it across partials.

## Wrapper partials with `yield`

Use a block partial when the wrapper is the reusable concept and the body must
remain flexible.

```erb
<%# app/views/application/_surface.html.erb %>
<%# locals: (title:, description: nil) %>

<section class="card border border-base-300 bg-base-100 shadow-sm">
  <div class="card-body">
    <header>
      <h2 class="card-title"><%= title %></h2>
      <% if description.present? %>
        <p class="text-sm text-base-content/70"><%= description %></p>
      <% end %>
    </header>

    <%= yield %>
  </div>
</section>
```

```erb
<%= render "application/surface",
  title: "Publishing schedule",
  description: "Review upcoming posts before they go live." do %>
  <%= render @scheduled_posts %>
<% end %>
```

Use this only when the wrapper is reused and meaningful. If callers need many
named slots, variant combinations, or behavior, use a ViewComponent.

## Layout regions with `content_for`

Layouts expose page-owned regions with named `yield` calls:

```erb
<title><%= content_for(:title) || "Pulse" %></title>
<%= yield :head %>
<%= yield %>
```

An action template fills those regions:

```erb
<% content_for :title, "Content calendar" %>

<% content_for :head do %>
  <meta name="description" content="Plan and review scheduled content">
<% end %>
```

Use named regions for layout concerns, not as an implicit way for one ordinary
partial to configure another.

## Extraction boundary

Keep markup inline when it is short, local to one page, and easier to read in
context. Extract when the fragment represents a stable concept, repeats, is a
collection item, or forms a useful block wrapper.

Choose a ViewComponent when the unit has a public variant API, multiple slots,
non-trivial presentation state, reusable behavior, or rendering states that
deserve focused tests.
