# Berberim

Berberim is a Flutter app for Android and iOS with Supabase Auth and PostgreSQL.

## Current Supabase migration
- Email/password authentication.
- Customer profiles and multiple business memberships through a unique join code.
- Barber business applications that remain pending until administrator approval.
- Multiple employees per business.
- Service catalogue with price and duration.
- Business opening hours and breaks stored in PostgreSQL.
- Appointment booking through a server-side PostgreSQL function.
- Database-level exclusion constraint prevents overlapping appointments for the same employee.
- Customer, employee, owner and administrator cancellation authorization.
- Row Level Security enabled on all public application tables.

## Supabase project
The app uses the public project URL and publishable key at build time. The publishable key is intended for client applications; never place a Supabase service-role key in Flutter or GitHub Actions build arguments.

- Project URL: https://tzwlbwhokvnjekwwpnsr.supabase.co
- Build defines: SUPABASE_URL and SUPABASE_ANON_KEY

## Build
GitHub Actions workflows build:
- Android release APK
- Unsigned iOS app bundle

Both workflows run on pushes to `supabase-migration` and can also be started manually. A signed IPA for TestFlight/App Store requires Apple signing credentials and provisioning.

## Important setup notes
- New Auth users receive a profile row through a database trigger.
- A business owner submits an application; only an administrator profile with `is_admin = true` can approve it.
- The first administrator must be provisioned securely in Supabase by an authorized project owner; the app deliberately does not allow users to grant themselves administrator privileges.
- Push notifications and scheduled appointment reminders still require APNs/FCM credentials and a scheduled server-side delivery worker. In-app booking and cancellation data is stored in PostgreSQL.
