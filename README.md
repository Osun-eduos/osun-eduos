# Osun EduOS

**Digital education management and intelligence for Osun State.**

This is the project hub: what Osun EduOS is, how it is designed and where it is going. The code lives in separate repositories listed below.

**Live prototype:** https://osun-eduos.pages.dev (sample data only)

## The problem

In many schools, examination results are still compiled by hand. Teachers calculate scores, schools consolidate them, and reports are forwarded to the Ministry. The process is slow, error-prone and hard to analyse across thousands of schools. Osun EduOS gives every school one digital route for submitting and managing education data, and gives the Ministry one place to see it.

## What the system covers

- **School management and registration**: school numbers, profiles, GPS mapping, classification by LGA, level and ownership, academic sessions and terms.
- **Student information**: records, enrolment, class allocation, transfers, academic history, attendance.
- **Examinations and results**: exam setup, CA and exam score entry, automatic calculation, configurable grading, report cards, class and subject analysis, school approval, electronic submission to the Ministry, historical records.
- **Teacher management**: registry, qualifications, subjects, postings, attendance, professional development.
- **Infrastructure monitoring**: classrooms, labs, libraries, sanitation, water, power, ICT, inspection reports.
- **Education intelligence**: State dashboards, LGA trends, development indicators, schools needing support.
- **Parent and student portal**: results, attendance, progress, announcements, notifications.
- **Offline-first**: offline score entry with encrypted local storage and automatic sync.

## Repositories

| Repository | What it is | Status |
| --- | --- | --- |
| **osun-eduos** (this one) | Overview, architecture, roadmap, project-wide decisions | Active |
| [eduos-web](https://github.com/Osun-eduos/eduos-web) | Web app for the Ministry, schools, teachers and parents | Clickable prototype |
| [eduos-api](https://github.com/Osun-eduos/eduos-api) | Application API, database and sync service | Planned |
| [eduos-mobile](https://github.com/Osun-eduos/eduos-mobile) | Teacher app for Android and iOS (Flutter): offline register and score entry | Active |
| [eduos-sync](https://github.com/Osun-eduos/eduos-sync) | Sync service for the mobile app (Go) | Active |
| [.github](https://github.com/Osun-eduos/.github) | Organisation profile and shared community files | Active |

## Documents

- [Architecture](docs/architecture.md): components, data model, offline sync, security and privacy.
- [Roadmap](docs/roadmap.md): phases from prototype to state-wide rollout.
- [Deployment](docs/deployment.md): putting the system online for a pilot.
- [Decisions](docs/decisions/): recorded technical decisions, including [programming languages and services](docs/decisions/0001-languages-and-services.md) and [Flutter for the mobile apps](docs/decisions/0002-flutter-for-mobile-apps.md).

## Get involved

Read the [contributing guide](https://github.com/Osun-eduos/.github/blob/main/CONTRIBUTING.md). Questions and proposals that affect more than one repository start as an issue here.

## Licence

Released under the [GNU Affero General Public License v3.0](LICENSE).
