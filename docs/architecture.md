# Architecture

This document describes the production architecture. Parts are built and running; the rest is planned. The **Status** column in the table below shows which is which. The clickable prototype in [eduos-web](https://github.com/Osun-eduos/eduos-web) (`prototype/`) is separate, front-end only and keeps its sample data in memory.

Decisions are recorded in [docs/decisions](decisions/): [0001 · Programming languages and where each service lives](decisions/0001-languages-and-services.md) and [0002 · Flutter for the mobile apps](decisions/0002-flutter-for-mobile-apps.md).

## Goals

1. **Works where schools are.** Score entry, attendance and inspections must work offline on low-cost Android phones and sync later.
2. **One source of truth.** Each record (school, student, teacher, score) is entered once at its source and flows upward: teacher → school → LGA → Ministry.
3. **Approval before visibility.** Results reach the Ministry and parents only after the school approves them.
4. **Privacy by design.** Personal data is minimised, encrypted and access-controlled by role and by school.
5. **Open and portable.** Open-source components only, deployable on government or commercial infrastructure without lock-in.

## Components

```
 Teacher apps (Android, iOS; offline)     Web app (schools, Ministry, parents)
        │  encrypted local store             │
        │                                    │
   Sync service (Go)                  Application API (TypeScript, NestJS)
   offline uploads from phones        auth, roles, validation, workflows, audit log
        │                                    │
        └──────────────┬─────────────────────┘
                       │        Job workers (Go): results, report cards, SMS
                       │
        ┌────────────────┼──────────────────┐
   PostgreSQL + PostGIS   Object storage    Job queue
   (records, GIS)        (documents, photos) (SMS, reports, sync)
                         │
              Analytics store and dashboards
```

| Layer | Technology | Status |
| --- | --- | --- |
| Web front end | TypeScript, React, Vite | **Built:** every module, from accounts, schools and students to results, staff, inspections, dashboards and the parent portal. Installable PWA planned. |
| Mobile app | Flutter (Dart), one codebase for Android and iOS | **Built:** app for parents, teachers, inspectors and LGA officers with offline register, score entry and inspections, encrypted SQLite (SQLCipher), ordered sync. See [decision 0002](decisions/0002-flutter-for-mobile-apps.md). |
| Core API | TypeScript, NestJS, Prisma | **Built:** REST/JSON for every module: accounts, schools, sessions, classes, students, transfers, attendance, results and grading, staff, inspections, indicators, notices and notifications. |
| Sync service | Go | **Built:** snapshot for offline work, exactly-once uploads applied through the core API. See [decision 0001](decisions/0001-languages-and-services.md). |
| Job workers | Go | Planned. Results, report cards and texts are handled inside the core API for now; separate workers only if the load needs them. |
| Database | PostgreSQL 16 (PostGIS later) | **Built.** One database shared by all services; the schema and migrations live in `eduos-api`. |
| Analytics | SQL in PostgreSQL first; a Go service or a warehouse only if needed | **Built:** Ministry and LGA dashboards and indicator reports, computed by the core API. |
| Messaging | Pluggable SMS gateway, push notifications | **Built:** SMS through KudiSMS, an in-app inbox, and push through Firebase once it is set up. Parents without smartphones get SMS only. |
| Auth | Built into `eduos-api`: Argon2id passwords (12+ characters, checked against leaked-password lists), 15-minute access tokens signed with ES256, rotating refresh tokens | **Built.** Roles: Ministry administrator, Ministry officer, LGA education officer and school inspector (read only, limited to an LGA), school administrator, teacher, parent. Go services check the same tokens with the API's public key and cannot issue their own. |
| Hosting | Web app on Cloudflare Pages; API, sync service and database in containers (Docker) | Web app and prototype on Cloudflare Pages. Host for the API and database to be decided; see [deployment](deployment.md). |

## Repositories

| Repository | Holds |
| --- | --- |
| [eduos-web](https://github.com/Osun-eduos/eduos-web) | Web app for the Ministry, schools, teachers and parents, and the clickable prototype |
| [eduos-api](https://github.com/Osun-eduos/eduos-api) | Core API (TypeScript) and the database schema and migrations for every service |
| [eduos-sync](https://github.com/Osun-eduos/eduos-sync) | Sync service for the mobile apps (Go) |
| [eduos-mobile](https://github.com/Osun-eduos/eduos-mobile) | Offline-first Flutter app for parents, teachers, inspectors and LGA officers, for Android and iOS |
| [osun-eduos](https://github.com/Osun-eduos/osun-eduos) | Architecture, roadmap and project-wide decisions |
| [.github](https://github.com/Osun-eduos/.github) | Organisation profile and shared community files |

Analytics, infrastructure-as-code and shared specifications (data model, OpenAPI, sync protocol) can move into their own repositories when that work starts.

## Core data model (summary)

- **School**: school number, name, LGA, level, ownership, GPS point, facilities, status.
- **Session / Term**: dates and state (upcoming, active, closed). Closing a term locks entry.
- **Student**: state-wide learner ID for life, biodata, linked parent accounts, current school, status.
- **Enrolment**: one row per student per school, with that school's admission number. Transfers close one row and open another, so history follows the student.
- **Class and placement**: class arms per school and session (for example JSS 2A) and one placement per student per session.
- **Transfer**: requested by the sending school, accepted or declined by the receiving school.
- **Teacher**: TRCN number, qualifications, subjects, current posting, posting history, training records.
- **Assessment setup**: components (e.g. CA 1, CA 2, Exam) with maximum marks per level and term; exam timetable.
- **Score**: student × subject × component × term, with entered-by, device and timestamps.
- **Result approval**: class × subject × term, moving through draft → submitted → approved → sent to Ministry.
- **Grading scale**: versioned bands per level, set by the Ministry.
- **Attendance**: student × day × status.
- **Inspection**: school × date × checklist × findings × priority.
- **Notification**: recipient, channel, template, delivery status.

## Offline sync

- Every change on the device is a small event (for example `score.set`) with a client-generated ID, written to an encrypted local queue.
- On reconnect, the app sends queued events in order. The server applies each event once (idempotency by event ID) and returns conflicts.
- Conflict rule: the most recent edit by an authorised user wins while the result is in draft; once a class-subject is submitted, edits are rejected and the teacher is told why.
- The device key is generated on the phone and never leaves it. The prototype demonstrates this with the Web Crypto API (AES-256-GCM).

## Security and privacy

- Compliance with the Nigeria Data Protection Act 2023, including a data protection impact assessment before launch.
- TLS everywhere; encryption at rest for the database, backups and devices.
- Role- and scope-based access: a teacher sees only their classes; a principal only their school; an LGA officer only their LGA.
- Full audit log of who changed which score or record, and when.
- Parents see only their own children's records.
- Data minimisation: no national ID numbers or biometric data unless the Ministry mandates them.

## Integrations (later phases)

- Exam bodies and State Universal Basic Education Board systems, via agreed data exchange formats.
- National data standards for school and learner identifiers, where available.
- Payment providers for fees in private schools (optional module).
