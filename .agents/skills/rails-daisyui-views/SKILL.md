---
name: rails-daisyui-views
description: >-
  Builds and refactors Pulse Rails ERB views with daisyUI components,
  theme-aware semantic colors, explicit partial locals, collection rendering,
  and block-based wrappers. Use when creating or changing pages, forms,
  layouts, or partials. Do not use for Turbo interaction design, Stimulus
  behavior, or non-view architecture decisions.
---

# Rails daisyUI Views

Build server-rendered Pulse interfaces that feel consistent in both configured
themes and whose partial dependencies are visible at every call site.

## Before editing

- Inspect `app/assets/stylesheets/application.css` for the currently configured
  daisyUI themes and tokens. The codebase is the source of truth; do not assume
  daisyUI's stock theme values.
- Inspect nearby views and shared partials before introducing a new pattern.
- Preserve the user's intended hierarchy and interaction. This skill governs
  implementation quality, not the product direction.

## daisyUI and theme rules

- Prefer an existing daisyUI component when it expresses the control or
  surface: `btn`, `input`, `select`, `textarea`, `checkbox`, `card`, `alert`,
  `badge`, `menu`, `tabs`, `modal`, `dropdown`, and similar components.
- Use daisyUI semantic theme classes for color: `base-100`, `base-200`,
  `base-300`, `base-content`, `primary`, `secondary`, `accent`, `neutral`,
  `info`, `success`, `warning`, and `error`, including their `*-content`
  counterparts.
- Build surface hierarchy with the base scale. A page commonly starts at
  `bg-base-200`, primary surfaces use `bg-base-100`, and borders use
  `border-base-300`.
- Use paired content colors when a semantic background is present, such as
  `bg-primary text-primary-content` or `alert-error`.
- Do not hardcode Tailwind palette colors, arbitrary hex values, inline color
  styles, or duplicate theme colors with `dark:` variants. The active daisyUI
  theme must control color.
- Use ordinary Tailwind utilities for layout, spacing, responsive behavior,
  sizing, and typography. Do not recreate a daisyUI component from utilities.
- Add a custom token or component override only when the implemented design has
  a repeated need that existing daisyUI APIs cannot express.
- Represent states semantically: errors with `error`, destructive actions with
  `btn-error`, confirmations with `success`, warnings with `warning`, and
  neutral supporting information with base or neutral colors.
- Keep accessible labels, focus states, disabled states, and visible validation
  feedback. An icon may support a label but must not replace an ambiguous label.
  Use the project's shared Tabler icon font rather than adding another icon
  dependency.

## Partial contracts

- Controller instance variables belong at the action-template boundary. A
  partial must not read `@user`, `@post`, or another controller-provided
  instance variable; pass the value as a local instead.
- Give every new or materially changed partial a strict-locals signature:

  ```erb
  <%# locals: (post:, compact: false) %>
  ```

- Make essential inputs required. Give a default only to a genuinely optional
  presentation choice. Prefer strict-local defaults over `local_assigns`.
- Keep the local API narrow and named for the concept the partial renders. Do
  not pass a large catch-all options hash or a controller/view context.
- Partials render markup. They may format simple display state, but they must
  not query records, authorize actions, mutate data, or contain business rules.
  Prepare those decisions before rendering.
- Use `class_names` for small conditional class changes. If variants, branching,
  behavior, and testable state form a public component API, use a ViewComponent
  instead of growing the partial indefinitely.

## Choosing a partial pattern

- Extract a partial for a stable repeated fragment, a collection item, a shared
  form, or a useful wrapper. Do not fragment a readable one-off page solely to
  reduce its line count.
- Put resource-specific partials beside their resource views. Use the canonical
  `_post.html.erb` style for the default representation so Rails can render
  `post` or `posts` directly.
- Put truly cross-feature presentation fragments in `app/views/application/`.
  Do not turn feature-specific markup into a global partial.
- Render collections through Rails rather than writing a large ERB `each`
  block. Keep empty-state markup explicit at the calling view.
- Use a block partial with `yield` when multiple callers share meaningful
  wrapper markup but supply different body content. Pass wrapper configuration
  as locals and keep one obvious primary body slot.
- Use layout-level named `yield` regions with `content_for` for page-owned
  sections such as `:title`, `:head`, or a layout sidebar. Do not use
  `content_for` as hidden data flow between ordinary partials.
- Avoid nested wrapper partials whose render chain is harder to understand than
  the repeated markup. Promote complex multi-slot UI to a ViewComponent.

When creating or substantially refactoring a partial, read
[references/partial-patterns.md](references/partial-patterns.md) for the
preferred call shapes and examples.

## Verification

Run the checks proportional to the change:

```bash
bun run erb:format:check
bun run build:css
mise exec -- bundle exec rspec spec/path/to/relevant_spec.rb
```

For a visual change, inspect the rendered page at relevant responsive sizes and
in both configured themes. Confirm form labels, validation states, keyboard
focus, and content contrast.

## Sources

- [Rails Partials Pro Tips](https://gist.githubusercontent.com/trouni/40c2562892357ee374acf0e5f9558733/raw/eedd0cf7c19a1d678349946224809ace8c80d530/rails_partials_tips.md)
- [Rails Layouts and Rendering](https://guides.rubyonrails.org/layouts_and_rendering.html)
- [Rails Action View Overview](https://guides.rubyonrails.org/action_view_overview.html)
