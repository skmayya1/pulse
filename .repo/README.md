# Local reference repositories

These shallow clones are local implementation references only. They are ignored
by Git and must never be imported wholesale into Pulse.

| Folder | Source | Stack | Use as reference for |
| --- | --- | --- | --- |
| `fizzy/` | `basecamp/fizzy` | Rails, Hotwire, Turbo, Stimulus | RESTful controller design, Kanban interactions, drag and drop, and real-time updates. |
| `once-campfire/` | `basecamp/once-campfire` | Rails, Hotwire, Action Cable | Turbo Streams, group chat, presence, and lightweight real-time collaboration. |
| `writebook/` | `basecamp/writebook` | Rails, Hotwire, Active Storage, Action Text | Media handling, rich content, markdown publishing, and focused model design. |
| `blackcandy/` | `blackcandy-org/blackcandy` | Rails, Hotwire, Turbo, Stimulus | Media sessions, native bridge patterns, and self-hosted streaming architecture. |
| `maybe/` | `maybe-finance/maybe` | Rails, Hotwire, Turbo, Stimulus, Tailwind | Modern Propshaft and Hotwire patterns, Tailwind UI, and background job organization. |

To refresh every local checkout:

```bash
for repository in .repo/*/.git; do
  git -C "${repository%/.git}" pull --ff-only
done
```

Before adapting a pattern, verify that it fits Pulse's team isolation, Pundit
authorization, provider-adapter boundaries, Sidekiq jobs, and product scope.
