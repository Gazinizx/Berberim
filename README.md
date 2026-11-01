# Berberim

Flutter application for Android and iOS, using Supabase Auth and PostgreSQL.

## Backend
- Supabase project: `tzwlbwhokvnjekwwpnsr`
- Client uses the project URL and publishable key. The publishable key is designed for client apps; never put a `service_role` or secret key in Flutter.
- RLS is enabled on all application tables.
- Booking and cancellation run through PostgreSQL RPC functions. An exclusion constraint prevents overlapping confirmed appointments for the same employee.
- Businesses are created as pending and require an administrator to activate them.
- Customer membership is established through the unique business join code.

## First administrator
Create the administrator's account through the app first. Then, in the Supabase SQL Editor, find the account and grant the initial administrator flag using the exact account email:

```sql
update public.profiles
set is_admin = true
where id = (
  select id from auth.users
  where lower(email) = lower('YOUR_ADMIN_EMAIL')
);
```

Replace the placeholder with the administrator account's email. Do not expose an admin/service-role key in the app.

## Run locally
```sh
flutter pub get
flutter run
```

The Supabase URL and publishable key are public client configuration and are currently supplied as build defaults in `lib/main.dart`.

## GitHub Actions
- **Build Android APK** creates a release APK artifact.
- **Build iOS App (unsigned)** creates an unsigned iOS app artifact. A signed IPA/TestFlight upload still requires Apple signing credentials and provisioning.

Both workflows run on pushes to `supabase-migration` and can also be started manually.

## Current implementation scope
Email/password auth, customer profile setup, join-code membership, business application/approval, employee and service management, opening-hours defaults, appointment creation/cancellation and realtime appointment list are wired to Supabase.

Push notifications/reminders, full weekly schedule and break editor, employee account invitations, and full appointment slot availability UI remain follow-up work; they are not claimed as complete yet.
