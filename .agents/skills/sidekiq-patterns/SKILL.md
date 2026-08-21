---
name: sidekiq-patterns
description: >-
  Designs and implements safe Sidekiq-backed Rails jobs for scheduled publishing,
  provider synchronization, notifications, webhooks, and retries. Use when work
  must run asynchronously or be retried; do not use for synchronous request work.
---

# Sidekiq Patterns

Pulse uses Sidekiq for asynchronous work. Jobs are delivery mechanisms, not domain workflows: put business decisions in a service and let the job invoke that service.

## Job contract

- Pass only primitive, serializable arguments such as IDs, strings, and timestamps. Never pass Active Record instances, relations, request objects, or secrets.
- Re-fetch records inside `perform`, scoped to the owning team/account where relevant.
- Make every job idempotent: a duplicate execution must not publish twice, send a duplicate notification, or corrupt state.
- Assign a deliberate queue and bounded retry policy. Retry known transient provider failures; discard missing/deleted records; surface permanent failures with redacted context.
- Keep `perform` short. Split fan-out and batch work into smaller jobs with explicit limits.

## Publishing and provider work

- Persist the intended action and its state before enqueueing. Use stable provider idempotency keys or local delivery records where available.
- Check current state when the job begins: skip cancelled, superseded, already-delivered, or no-longer-authorized work.
- Record attempts, failure class, safe error details, and provider response identifiers. Do not log access tokens, direct-message text, or user data.
- Use explicit HTTP timeouts, exponential backoff, and rate-limit-aware rescheduling in the provider adapter or service.
- Deduplicate jobs that can be triggered repeatedly, especially analytics syncs, webhook follow-up work, and scheduled publishing.

## Transaction boundary

Commit database state before enqueueing work. If a job depends on a write, enqueue it from an `after_commit` path or an outbox-style service boundary so a worker never observes uncommitted data.

## Testing

Test the observable job contract: correct IDs are enqueued, duplicate execution is safe, missing records are handled intentionally, and transient versus permanent provider failures follow the expected retry behavior. Mock provider HTTP clients, not internal services.
