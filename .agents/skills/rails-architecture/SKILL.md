---
name: rails-architecture
description: >-
  Guides Rails architecture decisions for Pulse. Use when deciding where code
  belongs, designing a feature, choosing between a service, query, form,
  policy, component, or job, or refactoring an existing implementation.
  Do not use for a narrow code edit whose placement is already clear.
---

# Rails Architecture

Pulse uses a layered Rails application: Hotwire for server-rendered UI, Pundit for authorization, Sidekiq for asynchronous work, PostgreSQL for persistence, and ViewComponent for reusable interface units.

## Routing a responsibility

| Need | Place it in |
| --- | --- |
| HTTP, parameters, response | Controller |
| Persistence, associations, local validation, simple predicate | Model |
| Multi-step workflow, provider call, or side effect | Service |
| Reused or complex relation/aggregate | Query |
| Authorization decision or policy scope | Pundit policy |
| Multi-model input and validation | Form object |
| Display-only formatting | Presenter |
| Reusable UI with behavior or variants | ViewComponent |
| Async, scheduled, or retryable work | Sidekiq job |
| Transactional email | Mailer |
| Small browser-only interaction | Stimulus controller |
| Partial page update or server-pushed change | Turbo Frame or Stream |

## Layer rules

- Controllers authenticate, authorize, call one workflow or query, and render or redirect. They do not contain domain logic, provider calls, or non-trivial queries.
- Models describe data and local invariants. Callbacks are limited to data normalization; they do not send mail, enqueue work, call providers, or broadcast UI updates.
- Services are explicit domain actions, named by resource and verb (`Posts::ScheduleService`). They expose `.call`, use a transaction for atomic writes, receive dependencies explicitly, and return an object that clearly represents success or failure.
- Queries receive the already-authorized team or account scope. They return a relation or a plain result, and prevent N+1 queries with intentional eager loading.
- Policies default to deny. Every record read or mutated must be scoped through the current team/account and authorized server-side.
- Components own rendering and presentational state. They never decide permissions or mutate business data.

## When to keep code simple

- Keep small, one-off CRUD in the controller when it remains clear.
- Use a model scope for a simple reusable filter; introduce a query only once joins, aggregates, or reuse make the intent clearer.
- Use a partial for static, one-off markup; introduce a ViewComponent for a reused component with a public API, variants, or behavior.
- Do not extract merely because code resembles another call site. Extract when the shared concept is stable and the resulting boundary is clearer.

## Pulse boundaries

- Keep social-provider code behind dedicated adapters or clients. OAuth, token refresh, rate limits, webhook verification, and provider payload translation never leak into controllers or core domain models.
- Publishing, comment replies, analytics synchronization, notifications, and retryable integrations are services orchestrated by Sidekiq jobs. Store provider IDs, delivery state, errors, and retry context.
- Team isolation is non-negotiable. A provider account, post, media asset, conversation, approval, or campaign is always queried from its owning team/account before authorization.
- AI suggestions are generated assistance, not autonomous side effects. They must not publish or send a reply without a user action.

## Feature checklist

1. Define the data, constraints, and migration.
2. Add or update the Pundit policy and scoped access.
3. Put complex writes in a service and complex reads in a query.
4. Add Sidekiq work for delayed or provider-dependent operations.
5. Render the interface with Rails, Turbo, and ViewComponents where reuse warrants it.
6. Add focused RSpec coverage for the risky behavior and integration boundary.
