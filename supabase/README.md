# Berberim Supabase backend

Production project: `esnrbyegnxykvsghsjjq` (Frankfurt, `eu-central-1`).

The Flutter app uses this project's Supabase URL and publishable key at build time. The publishable key is intended for client apps; authorization is enforced with RLS. Never place a service-role or secret key in Flutter or GitHub build arguments.

## Public tables

- `profiles`
- `businesses`
- `business_memberships`
- `employees`
- `employee_invites`
- `services`
- `business_hours`
- `business_breaks`
- `appointments`
- `notifications`

All public tables have Row Level Security enabled. Owner/customer/admin access is scoped through RLS policies. Indexes cover the app's owner, customer, employee, business, date-ordering and notification lookups. A PostgreSQL GiST exclusion constraint prevents overlapping pending/confirmed appointments for the same employee.

Privileged database implementations live in the non-exposed `private` schema. The public RPC endpoints are `SECURITY INVOKER` wrappers with execution limited to authenticated users; internal functions perform their own identity and ownership checks.

## App RPCs

- `create_business_application`: atomically creates a pending business, its owner employee record, and seven default opening-hour rows.
- `join_business_by_code`: joins an active business using the code embedded in its QR code.
- `leave_business`: removes only the signed-in customer's membership; appointment history is retained.
- `get_business_appointments`: returns only the caller's assigned appointments, or all business appointments for the business owner when requested.
- `create_employee_invite`: creates an employee and a short-lived, business-scoped invite code for an active business owner.
- `claim_employee_invite`: links a single-use, unexpired employee invite to the signed-in employee account; the employee then sees their own appointment dashboard.
- `get_available_slots`: returns free start times using the business-configured appointment interval, respecting opening hours, breaks and existing appointments.
- `book_appointment`: validates membership, business status, employee, service, opening hours, breaks and time before inserting.
- `cancel_appointment`: authorizes cancellation by the customer, assigned employee or business owner.
- `update_appointment_status`: allows the business owner, assigned employee or admin to mark an appointment completed/no-show.
- `review_business`: admin-only business approval/rejection/deactivation.
- `admin_set_user_blocked`: admin-only user blocking.

Appointment insert/cancellation triggers create in-app notifications for the customer, owner and assigned employee where applicable.

## First administrator

The app intentionally has no self-service admin promotion. After the first administrator account is created through Supabase Auth, a project owner must set that profile's `is_admin` flag from the Supabase SQL editor, matching the Auth user ID:

```sql
update public.profiles
set is_admin = true
where id = (select id from auth.users where email = 'ADMIN_EMAIL_HERE');
```

## Remaining deployment work

- Add `berberim://login-callback` to Supabase Auth → URL Configuration → Additional Redirect URLs so email confirmation returns to the mobile app.
- Configure APNs/FCM and a server-side push delivery worker for device push notifications.
- Configure a scheduled job for upcoming appointment reminders.
- Add Apple signing credentials before producing a TestFlight/App Store IPA.
