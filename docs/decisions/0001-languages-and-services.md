# 0001 · Programming languages and where each service lives

- **Status:** Accepted
- **Date:** 2026-11-24

## Context

The core API ([eduos-api](https://github.com/Osun-eduos/eduos-api)) is written in TypeScript with NestJS, Prisma and PostgreSQL. The web app ([eduos-web](https://github.com/Osun-eduos/eduos-web)) is TypeScript and React. Accounts, schools, students, classes and transfers are already built on this stack.

Later phases add work with a different profile:

- syncing scores and attendance from thousands of teachers' phones, often all at once after a network outage;
- bulk jobs such as results processing, report cards and SMS to parents;
- state-wide analytics over every school and student in Osun.

We considered TypeScript, Go and Rust for this work.

## Decision

| Part | Language | Why |
| --- | --- | --- |
| Core API: accounts, schools, students, classes, attendance, results workflow | **TypeScript (NestJS)** | Mostly records, permissions and approval workflows. NestJS and Prisma make these quick to build and safe to change, and the web app uses the same language and types. |
| Sync service for the Android and iOS apps (`eduos-sync`, when the apps need it) | **Go** | Many concurrent connections, idempotent writes and steady memory use under load. Single-binary deployment on modest servers. |
| Bulk jobs: results processing, report cards, SMS sending | **Go** | Long-running and parallel work that should not slow down the core API. |
| State analytics | **SQL in PostgreSQL first** (views and materialised views), **Go** if a dedicated service is needed | Most indicators are aggregations the database already does well. |
| Shared offline sync and encryption library | ~~Rust, only if adopted~~ | No longer relevant: the mobile app is built in Flutter ([decision 0002](0002-flutter-for-mobile-apps.md)). |

Rules that go with this:

1. **One database.** Go services read and write the same PostgreSQL database. The schema and migrations stay in `eduos-api` (Prisma) and are the single source of truth. Go services do not run their own migrations.
2. **One identity.** Go services accept the access tokens issued by `eduos-api` and apply the same roles and school scoping. They never issue their own logins.
3. **One audit log.** Every write a Go service makes on a user's behalf is recorded in the same `AuditLog` table.
4. **New services start only when needed.** We do not split a service out of the core API until there is a measured load or isolation reason, or the mobile apps need the sync service.

## Why not Go for everything

Go would use fewer server resources and deploy more simply. But the core API is mostly business rules, validation and permissions, where TypeScript with NestJS and Prisma is faster to develop and lets contributors work across the web app and the API in one language. TypeScript developers are also far easier to hire and train in Nigeria, which matters for long-term maintenance by the State.

## Why not Rust

Rust is the fastest and safest of the three, and it is the only one that could share code with the mobile apps. We are not using it for services because:

- **Maintainers.** Rust developers are rare in Nigeria and take months to train. The State must be able to keep this system running after launch. A TypeScript developer can become productive in Go within weeks.
- **The workload.** The heavy services mostly wait on the network and the database. Rust's speed advantage over Go is small for that kind of work.
- **Delivery speed.** Rust takes longer to write and compile. Go is simpler to read and review.
- **Team focus.** A small team is easier to staff with two server languages than three.

We will revisit Rust if the mobile apps and the sync service need to share one implementation of the sync protocol or the on-device encryption.

## Addendum, 2026-11-25: how the sync service writes

When building [eduos-sync](https://github.com/Osun-eduos/eduos-sync) we refined rule 1. The sync service **reads** the teacher's working set directly from PostgreSQL, which is fast and keeps phones' downloads small. It **writes** by calling eduos-api with the teacher's own access token, rather than writing registers and scores itself. This keeps every school rule (edit windows, class rolls, score limits, approval and release) in one place, so the web app and the mobile apps can never disagree. The sync service adds what phones need on top: batching, exactly-once delivery (the `SyncEvent` table), and ordered retries during outages. If load later requires it, individual writes can move into Go once their rules are covered by shared tests.

## Consequences

- Contributors to the core API and the web app need TypeScript only.
- Contributors to `eduos-sync` and job services need Go and read access to the Prisma schema in `eduos-api`.
- Changes to the database schema must consider Go services that read the same tables. Pull requests that change tables used by Go services must update those services in step.
- Shared contracts (the sync protocol and event formats) are documented in this repository so the API, the Go services and both mobile apps follow the same definitions.
