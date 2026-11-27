# Roadmap

Timelines are indicative and depend on funding, team size and Ministry priorities.

## Phase 0 · Prototype (done)

- Clickable front-end prototype covering every module in the concept note, with sample data.
- Public demo at https://osun-eduos.pages.dev.
- Stakeholder walkthroughs with the Ministry, school heads and teachers.

## Phase 1 · Core registry and results (software done, pilot next)

- ✅ Production API, database and authentication with roles (milestone 1).
- ✅ School registration and school numbers; academic sessions and terms (milestones 1 and 4).
- ✅ Student records, enrolment and class allocation (milestone 2).
- ✅ Exam setup, score entry (web), grading systems, report cards (milestone 4).
- ✅ School approval and electronic submission to the Ministry (milestone 4).
- ✅ LGA education officer and school inspector accounts (read only, limited to an LGA), state holidays, and student import from spreadsheets.
- Pilot in a small number of schools in a few LGAs.

## Phase 2 · Offline app and day-to-day operations

- ✅ Teacher app (Flutter, Android and iOS) with offline score entry and attendance, encrypted local storage, background sync, and the Go sync service.
- ✅ Daily attendance on the web (milestone 3), with absence texts to parents through KudiSMS.
- ✅ Student transfers between schools (milestone 2).
- ✅ Staff registry, postings and transfers, qualifications and training records.
- ✅ Infrastructure inspections with photos on the mobile app, for inspectors and LGA officers.

## Phase 3 · Intelligence and parents

- ✅ Ministry dashboards, LGA comparisons and trends.
- ✅ Education indicators (enrolment by sex, gender parity, pupils per teacher, qualified teachers, attendance, pass rates, school condition) with Excel, PDF and CSV reports.
- ✅ Parent portal on the web and in the app, with notifications (inbox, SMS, and push once Firebase is set up). Student logins to follow.
- ✅ Archive of past sessions.

## Prototype parity (done)

Every screen in the original prototype (osun-eduos.pages.dev) now exists in the product: school profiles with maps, results submission tracking and class analysis, editable grading, exam timetables, class allocation, verifiable report cards, staff register and clock-in, training and subject-shortage figures, minimum infrastructure standards with follow-up, enrolment ratios from population estimates, LGA comparisons over terms, and a fuller parent portal.

## Security before the pilot (done)

- Two-step sign-in with an authenticator app, required for Ministry administrators and officers and optional for everyone else, with recovery codes and administrator resets.
- Passwords of at least 12 characters, checked against common and leaked passwords.
- Access tokens signed with ES256; only the API holds the private key.
- Content-Security-Policy and HTTPS-only headers on the web app; CodeQL code scanning and Dependabot on every repository.

Still needed before real data goes in: a data protection impact assessment, a retention policy and a named data protection officer under the Nigeria Data Protection Act 2023, and a decision on where the database is hosted.

## Phase 4 · State-wide rollout

- Training for teachers, school administrators and LGA officers.
- Onboarding of all public schools, then private schools.
- Support desk, monitoring and service-level targets.

## Ideas under discussion

- Yoruba language interface.
- USSD access for parents without smartphones.
- Integration with exam bodies and national education data systems.
- Learning-gap analytics to target teacher training and remedial support.

Have a suggestion? Open a feature request.
