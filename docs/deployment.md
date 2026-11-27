# Deploying Osun EduOS for a pilot

This guide puts the real system online: the database, the API and the sync service for the mobile app on [Render](https://render.com), and the web app on [Cloudflare Pages](https://pages.cloudflare.com). It takes about 30 minutes, most of it waiting for builds. The Render side is described in [`render.yaml`](https://github.com/Osun-eduos/eduos-api/blob/main/render.yaml) in eduos-api and the Cloudflare side in [`wrangler.toml`](https://github.com/Osun-eduos/eduos-web/blob/main/wrangler.toml) in eduos-web, so the same setup can be recreated at any time.

The clickable prototype stays on Cloudflare Pages at https://osun-eduos.pages.dev and is not affected.

## What gets created

| Service | Address | Render plan | About |
| --- | --- | --- | --- |
| Database `osun-eduos-db` | private only | `0.1c-256mb` | PostgreSQL 16 with daily backups |
| API `osun-eduos-api` | https://osun-eduos-api.onrender.com | `0.5c-512mb` | Applies database migrations on every deploy |
| Sync `osun-eduos-sync` | https://osun-eduos-sync.onrender.com | `0.5c-512mb` | Used by the mobile app |
| Web app `osun-eduos-app` | https://osun-eduos-app.pages.dev | Cloudflare Pages (free) | Calls the API through `/api` on its own address |

Expect roughly **US$20 to 30 a month** on Render; Render shows the exact price before you apply the Blueprint. The plans can be changed later in each service's settings. All services run in Render's **Frankfurt** region, the closest to Nigeria. Before real student data goes in, confirm with the Ministry that hosting outside Nigeria is acceptable under the Nigeria Data Protection Act. The same containers can later move to a State data centre or a Nigerian cloud region.

## Steps

1. **Create a Render account** at https://dashboard.render.com and sign in with GitHub. Use an account the Ministry controls in the long run. Add a payment method under *Billing*.
2. **Give Render access** to the `Osun-eduos` organisation when GitHub asks: allow `eduos-api`, `eduos-sync` and `eduos-web`.
3. **New > Blueprint**, choose `Osun-eduos/eduos-api`, and keep the blueprint name. Render reads `render.yaml` and lists the three resources.
4. Render asks for three values for the **first Ministry administrator**:
   - `SEED_ADMIN_NAME`: their full name.
   - `SEED_ADMIN_EMAIL`: the email they will sign in with.
   - `SEED_ADMIN_PASSWORD`: a **temporary** password of at least 8 characters, with letters and a number. They must change it the first time they sign in.
5. **Apply.** The database starts first, then the three services build. The first build takes 5 to 10 minutes.
6. When `osun-eduos-api` shows **Live**, open https://osun-eduos-api.onrender.com/health. It should say `{"status":"ok"}`.
7. Put the web app on Cloudflare Pages (next section), open https://osun-eduos-app.pages.dev and sign in as the Ministry administrator. Choose a new password when asked.
8. In Render, open `osun-eduos-api` > *Environment*, **delete** `SEED_ADMIN_NAME`, `SEED_ADMIN_EMAIL` and `SEED_ADMIN_PASSWORD`, and save. They are no longer needed. The administrator is created only once, even if the values stay.

If Render gives a service a different address because the name is taken, update `API_ORIGIN` in `eduos-web/wrangler.toml`, and use the new addresses for the mobile app below.

## The web app on Cloudflare Pages

The web app is a static site plus one small Cloudflare function (`functions/api/[[path]].ts`) that passes `/api/*` on to the API. The browser only ever talks to the web app's address, so the sign-in cookie stays first-party and no cross-site settings are needed.

**First deploy, from a Mac or PC** with Node 22 and a Cloudflare account:

```
cd eduos-web
npm ci && npm run build
npx wrangler@4.161.0 login
npx wrangler@4.161.0 pages project create osun-eduos-app --production-branch=main
npx wrangler@4.161.0 pages deploy --branch=main
```

Wrangler reads the project name, the `dist` folder and the API address from `wrangler.toml`. The site is then at https://osun-eduos-app.pages.dev. To use your own domain, add it under the project's *Custom domains* in Cloudflare, then add that address to `WEB_ORIGIN` on the API in Render (comma-separated).

**Automatic deploys from GitHub** (optional): in `Osun-eduos/eduos-web` > *Settings* > *Secrets and variables* > *Actions*, add the secrets `CLOUDFLARE_API_TOKEN` (a token with *Cloudflare Pages: Edit*) and `CLOUDFLARE_ACCOUNT_ID`, and the variable `CLOUDFLARE_DEPLOY_APP` = `true`. Every push to `main` then builds and deploys the app. Set `CLOUDFLARE_PAGES_PROJECT` = `osun-eduos` as well to redeploy the prototype when it changes.

Cloudflare's free plan allows 100,000 function requests a day, which covers a pilot. For state-wide use, move the Cloudflare account to the Workers Paid plan (about US$5 a month for 10 million requests).

`TRUST_PROXY` is `2` on the API because web requests pass through Cloudflare and then Render; this lets the sign-in rate limit see each visitor's own address. Accounts are also locked after repeated wrong passwords, so a visitor who disguises their address still cannot guess passwords.

## Set up the pilot

Signed in as the Ministry administrator on the web app:

1. **Sessions and terms**: create the current academic session and its terms, with the score split, positions and senior secondary grading.
2. **Schools**: register the pilot schools, each with its administrator. Each school administrator gets a temporary password to pass on privately.
3. School administrators then create classes, add teachers and parents, enrol students and assign subjects.

## The mobile app

Point the app at the live servers in one of two ways:

- **For the pilot APKs (recommended):** in GitHub, open `Osun-eduos/eduos-mobile` > *Settings* > *Secrets and variables* > *Actions* > *Variables*, and add:
  - `EDUOS_API_URL` = `https://osun-eduos-api.onrender.com`
  - `EDUOS_SYNC_URL` = `https://osun-eduos-sync.onrender.com`

  Every push then builds APKs that use these addresses (download them from the CI run's artifacts).
- **On a phone with any build:** on the sign-in screen, tap *Server settings* and enter the two addresses.

For APKs that can be published, add the upload key secrets too (see *Release signing* in the eduos-mobile README).

## Absence texts and inspection photos

Both work without these settings (texts are recorded but not sent; photos are kept in the database), so the pilot can start first. On the API service in Render, under *Environment*:

- **Texts (KudiSMS):** in your KudiSMS dashboard, register a **corporate sender ID** (up to 11 characters, e.g. `OsunEduOS`) and wait for approval, then copy the API key from the developers section. Set `KUDISMS_TOKEN` and `KUDISMS_SENDER_ID`. Then send a test from *Text messages* in the web app. Keep the KudiSMS account topped up; the Ministry sees the balance on that page.
- **Photos (S3-compatible storage):** create a private bucket, for example in Cloudflare R2, and an access key limited to that bucket. Set `S3_BUCKET`, `S3_ENDPOINT` (for R2: `https://<account id>.r2.cloudflarestorage.com`), `S3_ACCESS_KEY_ID` and `S3_SECRET_ACCESS_KEY`. Photos added before this stay in the database and still display.

## Push notifications for parents (optional)

Parents already get an inbox and SMS. To also push notifications to the parent app:

1. Create a Firebase project at console.firebase.google.com, and add an Android app with the package name `org.osuneduos.teacher` (and an iOS app with the same bundle ID once the Apple Developer account is ready).
2. In *Project settings* > *Service accounts*, generate a private key. Paste the whole JSON file into `FIREBASE_SERVICE_ACCOUNT` on the API in Render.
3. In GitHub, `Osun-eduos/eduos-mobile` > *Settings* > *Secrets and variables* > *Actions* > *Variables*, add `FIREBASE_API_KEY`, `FIREBASE_PROJECT_ID`, `FIREBASE_SENDER_ID` and `FIREBASE_ANDROID_APP_ID` from the Android app's settings. The next APKs have push switched on.

## Updates and backups

- **Deploys:** every merge to `main` in eduos-api or eduos-sync deploys that service automatically. eduos-web deploys automatically once the Cloudflare secrets above are set; until then, run the deploy command from a Mac or PC. The API applies new database migrations before it starts.
- **Backups:** Render backs up the database daily. Before a big change, take a manual backup from the database's *Backups* page.
- **Logs:** each service's *Logs* page in Render. The API's activity log is also in the web app, under *Activity*.
- **Secrets:** the access-token secret is generated by Render and shared between the API and the sync service. To rotate it, edit `JWT_ACCESS_SECRET` on the API. Everyone is then signed out, and the sync service picks up the new value on its next deploy.
