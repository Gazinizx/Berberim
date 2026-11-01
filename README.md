# Berberim

Berberim is a Flutter appointment app for barber businesses, their staff, and customers. The active backend is **Supabase** (PostgreSQL, Auth, RPC and Row Level Security). Firebase is not used.

## App experience

- **Customers:** join one barber business with a code, book by service, employee, date and live availability, view appointment history, cancel eligible appointments, edit their profile, and leave their business to enter a new code.
- **Business owners:** daily appointment overview, employee filter, invite-code based team onboarding, employee activation, services and prices, business hours and breaks.
- **Workers:** separate role-based panel, own appointments and customer details, status updates, personal working hours, breaks and time off.
- **Scheduling:** 30-minute candidate slots filtered by service duration, business hours, employee hours, breaks, leave and existing appointments. The database prevents overlapping active appointments for the same employee.
- **Access control:** Supabase RLS and authenticated RPC functions restrict owner, worker and customer access.

## Backend

The active Supabase project is configured through SUPABASE_URL and SUPABASE_ANON_KEY Dart defines. The public publishable/anon key is intended for client apps; authorization is enforced by database policies and functions. Never place a service-role key in the app.

The professional app entrypoint is lib/professional_main.dart. Android APK workflow builds this entrypoint. The unsigned iOS workflow is prepared for the same entrypoint but is **not run automatically from this feature branch**.

## Build

- GitHub Actions → **Build Android APK** creates the Android release artifact.
- GitHub Actions → **Build iOS App (unsigned)** is manual-only; run it only when an iOS build is explicitly requested.
