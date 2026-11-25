# 0002 · Flutter for the mobile apps

- **Status:** Accepted
- **Date:** 2026-11-25
- **Replaces:** the native Kotlin (Android) and Swift (iOS) apps proposed in the architecture

## Context

Teachers need an offline app for the register and score entry, and later inspectors for school visits. The original plan was two native apps, Kotlin with Jetpack Compose for Android and Swift with SwiftUI for iOS, in two repositories (`eduos-android`, `eduos-ios`).

## Decision

The teacher app is built **once, in Flutter (Dart)**, for both Android and iOS, in one repository: [eduos-mobile](https://github.com/Osun-eduos/eduos-mobile). `eduos-android` was renamed to `eduos-mobile`, and `eduos-ios` is archived.

| Concern | Choice |
| --- | --- |
| Framework | Flutter (stable), Material 3 |
| Local data | SQLCipher-encrypted SQLite (`sqflite_sqlcipher`), key generated on the phone |
| Secrets | Android Keystore / iOS Keychain (`flutter_secure_storage`) |
| Sync | Ordered outbox sent to [eduos-sync](https://github.com/Osun-eduos/eduos-sync); see [decision 0001](0001-languages-and-services.md) |
| State | `provider` with a single app state object |

## Why

- **One codebase, one team.** Every feature, fix and security update ships to Android and iOS together, from the same code and tests. Two native apps would need two skill sets and twice the work for a small team.
- **Same behaviour on both platforms.** Offline rules (edit windows, mark limits, grading) are written once, so the two apps cannot drift apart.
- **Good fit for low-cost Android phones.** Flutter compiles to native code. Release APKs split by phone type are about 18 to 22 MB.
- **Developers.** Flutter is widely used by Nigerian mobile developers, so the State can hire and train for it.

## Trade-offs

- **App size.** A Flutter app is somewhat larger than a minimal native one. Per-ABI APKs and Play Store app bundles keep downloads reasonable.
- **Platform features.** Deep platform features (background work scheduling, device management) go through plugins. Background sync when the app is closed is not built yet. Today the app syncs when opened, when it reconnects, every 10 minutes while open, and on demand.
- **Another language.** Dart joins TypeScript and Go. It is a small, familiar language for anyone who knows TypeScript.

The Rust option in decision 0001 (sharing sync and encryption code between the server and the apps) is no longer relevant, because the apps do not run Rust. If code is ever shared, it would be the sync protocol definition, not an implementation.
