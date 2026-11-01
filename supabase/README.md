# Supabase backend

Project: `tzwlbwhokvnjekwwpnsr` (Europe/Paris)

The live Supabase project has the following public tables, all protected by RLS:

- `profiles`
- `businesses`
- `business_memberships`
- `employees`
- `services`
- `business_hours`
- `business_breaks`
- `appointments`
- `notifications`

Important RPCs:

- `create_business_application`: atomically creates a pending business, owner employee record, and default opening hours.
- `join_business_by_code`: joins an active business with its unique code.
- `book_appointment`: validates membership, business status, employee, service, opening hours, breaks, and time before inserting.
- `cancel_appointment`: authorizes cancellation by the customer, assigned employee, business owner, or admin.
- `review_business`: admin-only business approval/rejection/deactivation.
- `admin_set_user_blocked`: admin-only user blocking.

A PostgreSQL exclusion constraint prevents overlapping confirmed appointments for the same employee. Appointment insert/cancellation triggers write in-app notifications to the relevant accounts.

## First administrator

The app intentionally has no self-service admin promotion. After the first administrator account is created through Supabase Auth, a project owner must set that profile's `is_admin` flag from the Supabase SQL editor, matching the Auth user ID:

```sql
update public.profiles
set is_admin = true
where id = (select id from auth.users where email = 'ADMIN_EMAIL_HERE');
```

Never expose a service-role key in the Flutter app.

## Remaining deployment work

- Configure APNs/FCM and a server-side push delivery worker.
- Configure a scheduled job for upcoming appointment reminders.
- Run the Android and iOS GitHub Actions builds and resolve any compiler/analyzer findings.
- Add Apple signing credentials before producing a TestFlight/App Store IPA.
