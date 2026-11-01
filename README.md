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
- GitHub Actions Android release APK build.

## Required deployment configuration
This repository intentionally does not contain Firebase project credentials.
Set Flutter build defines for FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID, and FIREBASE_PROJECT_ID to activate the app.
Deploy Cloud Functions and Firestore rules with a Firebase project:
`firebase deploy --only functions,firestore:rules`

The first administrator profile must be provisioned by a trusted administrator using Firebase Admin SDK; never grant admin role from the client app.

## Build
GitHub Actions -> **Build Android APK**. The generated APK is uploaded as a workflow artifact.
