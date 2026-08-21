# Pulse

Pulse is a Rails social-media operations platform for influencers and small teams.

## Stack

- Ruby on Rails, Hotwire (Turbo and Stimulus), Tailwind CSS, and daisyUI
- PostgreSQL for persistence
- Redis and Sidekiq for background work
- Bun for JavaScript and CSS tooling

## Setup

```bash
bun run setup
```

This installs the `mise` toolchain, starts project-local PostgreSQL and Redis when they are not already running, installs dependencies, and prepares the database. Copy `.env.example` to `.env` only when local overrides are needed.
Install `libvips` (`brew install vips` on macOS) before generating Active Storage image variants.

## Development

```bash
bun dev
```

This starts Rails, Bun's JavaScript build watcher, Tailwind's CSS watcher, Sidekiq, and Clockwork. Use `bin/rails server` or `bundle exec sidekiq -C config/sidekiq.yml` individually when needed.

Use `bun run services:start` to start or verify PostgreSQL and Redis independently.

## tmux workspace

```bash
bun run launch
```

This opens tabs for the Rails server, Sidekiq, Clockwork, Rails console, and an empty playground shell. Use `./tmux.sh --detach` to create the workspace without attaching.

## Checks

```bash
bun run test
bun run lint
bun run format
bun run format:fix
bin/brakeman --no-pager
bundle exec bundler-audit check --update
```

`bun run lint` checks Ruby with StandardRB and JavaScript/CSS with Biome. `bun run format` also verifies ERB with Herb. Use `bun run format:fix` to apply the available fixes.
