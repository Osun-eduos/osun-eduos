# Proposed architecture

This document describes the intended production architecture. The current prototype ([eduos-web](https://github.com/Osun-eduos/eduos-web)) is front-end only and keeps all data in memory. Everything below is a proposal for discussion, not a description of shipped code.

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
        └──────────── sync API ──────────────┘
                         │
                  Application API
       (auth, roles, validation, workflows, audit log)
                         │
        ┌────────────────┼──────────────────┐
   PostgreSQL + PostGIS   Object storage    Job queue
   (records, GIS)        (documents, photos) (SMS, reports, sync)
                         │
              Analytics store and dashboards
```

| Layer | Proposed technology | Notes |
| --- | --- | --- |
| Web front end | TypeScript, React or Svelte, PWA | Same UI patterns as the prototype; installable; works on 3G |
| Mobile apps | Kotlin + Jetpack Compose (Android), Swift + SwiftUI (iOS) | Native apps with the same behaviour: offline queue, encrypted SQLite (SQLCipher), background sync |
| API | Node.js (NestJS) or Python (Django) | REST/JSON, OpenAPI spec, idempotent sync endpoints |
| Database | PostgreSQL 16 + PostGIS | Row-level security per school and LGA |
| Analytics | Materialised views or a separate warehouse (e.g. ClickHouse), Apache Superset or Metabase | Ministry dashboards and indicator reports |
| Messaging | Pluggable SMS gateway, push notifications | Parents without smartphones get SMS only |
| Auth | OpenID Connect (Keycloak) | Roles: teacher, school admin, principal, LGA officer, Ministry officer, inspector, parent |
| Hosting | Containers (Docker), state data centre or a Nigerian cloud region | Static front end can sit on a CDN |

## Repositories

| Repository | Holds |
| --- | --- |
| [eduos-web](https://github.com/Osun-eduos/eduos-web) | Web app for the Ministry, schools, teachers and parents (today: the clickable prototype) |
| [eduos-api](https://github.com/Osun-eduos/eduos-api) | Application API, database schema, sync endpoints, notifications |
| [eduos-android](https://github.com/Osun-eduos/eduos-android) | Offline-first Android app for teachers and inspectors |
| [eduos-ios](https://github.com/Osun-eduos/eduos-ios) | Offline-first iOS app for teachers and inspectors |
| [osun-eduos](https://github.com/Osun-eduos/osun-eduos) | Architecture, roadmap and project-wide decisions |
| [.github](https://github.com/Osun-eduos/.github) | Organisation profile and shared community files |

Analytics, infrastructure-as-code and shared specifications (data model, OpenAPI, sync protocol) can move into their own repositories when that work starts.

## Core data model (summary)

- **School**: school number, name, LGA, level, ownership, GPS point, facilities, status.
- **Session / Term**: dates and state (upcoming, active, closed). Closing a term locks entry.
- **Student**: admission number, biodata, guardian contacts, current enrolment (school, class arm), status.
- **Enrolment history**: one row per student per term and school. Transfers close one row and open another, so history follows the student.
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
