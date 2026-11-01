# Berberim

Fresh Flutter application for a multi-shop barber appointment service.

## Implemented in source
- Email/password sign-in and account creation.
- Customer registration using a shop code.
- Barber application and administrator review flow.
- Per-shop service management and customer appointment lists.
- Callable backend booking transaction with a unique slot lock.
- Cancellation and FCM notification functions.
- Firestore rules that deny client-side writes to profiles, applications, bookings, and slot locks.
- GitHub Actions Android release APK and unsigned iOS app builds.

## Required deployment configuration
This repository intentionally does not contain Firebase project credentials.
Add these GitHub Actions repository secrets to activate the APK: FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID, FIREBASE_PROJECT_ID, and optionally FIREBASE_STORAGE_BUCKET. Without them the APK intentionally opens a setup screen instead of pretending a live backend exists.
Deploy Cloud Functions and Firestore rules with a Firebase project:
`firebase deploy --only functions,firestore:rules`

During Functions deployment, set the Firebase parameter ADMIN_EMAIL to the administrator's exact Firebase Auth email. Create an account with that email in the app, then tap "Yönetici hesabını etkinleştir". The callable verifies the configured email server-side and only initializes an account that has no profile. Never grant admin role directly from the client.

## Build
GitHub Actions -> **Build Android APK** for an APK artifact or **Build iOS App (unsigned)** for the iOS app bundle. A signed IPA for TestFlight/App Store still requires the Apple signing certificate, provisioning profile, and matching iOS Firebase app configuration.
