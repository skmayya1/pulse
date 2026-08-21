**Stack:** Build Pulse with Ruby on Rails, Hotwire (Turbo and Stimulus), PostgreSQL, Redis, Sidekiq, Pundit, ViewComponent, and RSpec. Prefer Rails conventions and server-rendered HTML before custom JavaScript or a separate frontend API.

**Diff:** Keep changes small and surgical. Follow local patterns, make the fewest abstractions needed, and avoid unrelated refactors.

**Architecture:** `controllers/` are thin request orchestrators; `models/` handle persistence, associations, validations, scopes, and simple predicates; `views/` contain ERB markup only; `services/` own business workflows and side effects; `queries/` hold complex database queries; `forms/` coordinate multi-model forms; `policies/` own Pundit authorization; `presenters/` format data for views; `components/` hold reusable tested ViewComponents; `jobs/` contains Sidekiq work; and `mailers/` always provide HTML and text templates.

**Controllers:** Authenticate, authorize, call a service or query, and render or redirect. Do not place business logic, complex queries, external API calls, or data mutations beyond simple parameter handling in controllers.

**Models:** Keep models focused on persistence and local invariants. Use callbacks only for local data normalization such as `before_validation` or `before_save`; emails, jobs, webhooks, and other side effects belong in services.

**Services:** Name services by domain and action, such as `Posts::ScheduleService`. Expose a `.call` entry point, use explicit dependencies, wrap atomic multi-record writes in transactions, and return a clear result object rather than relying on hidden state.

**Queries:** Put reused or non-trivial database reads in named query objects such as `Posts::SearchQuery`. Return relations or simple value objects, scope by team or account first, eagerly load associations intentionally, and avoid N+1 queries.

**Forms and presenters:** Use form objects for multi-model input and cross-model validation. Use `SimpleDelegator`-based presenters only for view formatting; do not move domain rules into presenters.

**Components:** Use ViewComponents for reusable or stateful interface units. Give components a narrow API, keep business logic out of templates, and add component tests when behavior or rendering states could regress.

**Naming:** Use singular PascalCase models, singular `*Policy` and `*Presenter` classes, plural PascalCase controllers, descriptive `*Job` and `*Form` classes, and namespaced `*Service` and `*Query` classes, for example `Posts::CreateService` and `Posts::SearchQuery`.

**Authorization:** Use Pundit for every protected action with default-deny policies. Enforce organization, team, and role permissions server-side on every read and write, and always scope records through the current organization or team.

**Hotwire:** Use Turbo Frames for localized page updates and Turbo Streams for server-pushed UI changes. Keep Stimulus controllers small, declarative, and limited to browser behavior; every important form and action must work with progressive enhancement.

**Sidekiq:** Jobs must be small, idempotent, retry-safe, and passed only primitive identifiers—not Active Record objects. Re-fetch records in `perform`, define bounded retries for external failures, and guard against duplicate enqueues.

**Scheduling:** Run publishing, analytics syncs, notifications, webhooks, and provider retries through Sidekiq. Store delivery state and provider IDs so work can be safely retried and audited.

**Integrations:** Wrap each external provider in a dedicated client or adapter. Set explicit HTTP timeouts, handle rate limits and transient failures, validate webhook signatures, and normalize provider payloads before they reach domain logic.

**Migrations:** Generate migrations through Rails, make them reversible where possible, and never hand-edit `db/schema.rb`. Add indexes concurrently in a separate migration using `disable_ddl_transaction!` and `algorithm: :concurrently`.

**Data changes:** Keep schema migrations separate from data backfills. Make backfills resumable, batched, observable, and safe to run repeatedly; do not load large tables into memory.

**Database integrity:** Validate user-controlled input at model and request boundaries, but do not mistake validations for authorization. Add database constraints and unique indexes for critical invariants.

**Security:** Keep credentials in Rails credentials or environment variables. Never log tokens, passwords, private messages, or personal data; verify webhook signatures and use CSRF protection for browser requests.

**Caching:** Cache only data that is safe to share at its cache scope. Never use `current_user` or private team data in shared cached fragments, and define invalidation before introducing a cache.

**Errors:** Fail loudly and handle known errors deliberately. Do not swallow exceptions with broad rescues; report actionable failures with redacted structured context.

**TDD:** Follow Red → Green → Refactor: write a failing test for the desired behavior, implement the smallest passing change, then improve the structure while keeping tests green.

**Testing:** Add focused regression tests for risky behavior: authorization, data writes, service objects, jobs, provider adapters, schedules, and API contracts. Prefer real objects and factories; mock only external services.

**RSpec:** Use readable `describe` and `context` blocks, verify observable behavior rather than implementation, and avoid `receive_message_chain`, `allow_any_instance_of`, and mocks of internal application services.

**Commands:** Run `bundle exec rspec` for the full suite, `bundle exec rspec spec/path/to_spec.rb` for a file, and `bundle exec rspec spec/path/to_spec.rb:25` for a line. Use `bundle exec rubocop -a`, `bin/brakeman --no-pager`, `bundle exec bundler-audit check --update`, `bin/rails db:migrate`, `bin/rails db:migrate:status`, and `bin/rails console` as needed.

**Quality:** Run the relevant tests, RuboCop, and security checks for every change. Follow the repository configuration; do not bypass failures without documenting why.

**Routes and APIs:** Keep routes RESTful, version public APIs deliberately, validate parameters explicitly, and update API documentation and request specs whenever a contract changes.

**Observability:** Add actionable monitoring around jobs and provider calls with entity and correlation IDs. Exclude secrets and user content, and avoid noisy log events that no one will act on.

**Documentation:** Update setup, environment-variable, and operational documentation with any behavioral or configuration change. Use [PLAN.md](PLAN.md) only for product scope and MVP decisions.

**Reference repositories:** `.repo/README.md` lists local, ignored repositories and links used only for planning and implementation inspiration. Inspect their current code before borrowing a pattern, then adapt it to Pulse's architecture, permissions, provider integrations, and product scope; never copy product-specific behavior blindly.

**Scratch files:** Put temporary scripts and debugging artifacts in `/tmp`, then remove them. Do not commit generated files, local databases, logs, or credentials.
