# Supabase backend

Project: tzwlbwhokvnjekwwpnsr (Europe/Paris)

The active app uses Supabase Auth, PostgreSQL, RPC functions and Row Level Security. Firebase is not used. The Flutter client contains only the public publishable key; never put a service-role key in the app.

## Main tables

- profiles, businesses, business_memberships
- employees, employee_invites, business_reviews
- services, business_hours, business_breaks
- employee_hours, employee_breaks, employee_time_off
- appointments, notifications

## Role and access model

- Customer accounts join one active business using its code. The customer can leave from Profile; the membership row is deleted, but appointment history remains readable.
- Owners create worker records and short-lived invite codes. A customer account claims a code and is promoted to the worker role by a server-side RPC. The code can be claimed once and expires after seven days.
- Workers can read their own employee row, assigned appointments, customer contact details for those appointments, and their own availability. They cannot manage another worker or business settings.
- Owners manage their business, employees, services, appointments and schedules.
- Role changes are blocked by the profile update RLS policy; the claim RPC is the authorized path to the worker role.

## Scheduling RPCs

- create_employee_invite: owner-only worker creation and invite-code issue.
- claim_employee_invite: one-time worker account linking.
- join_business_by_code / leave_business: customer business membership lifecycle.
- get_available_slots: returns employee-specific 30-minute starts, filtered by service duration, business/employee hours, breaks, time off and existing appointments.
- book_appointment: revalidates the schedule server-side and inserts the appointment.
- reschedule_appointment: moves a customer's confirmed appointment only to a currently available slot.
- submit_business_review: accepts one 1–5 star review from the customer for a completed appointment.
- update_appointment_status: owner or assigned worker updates status.

An exclusion constraint prevents overlapping pending/confirmed appointments for the same employee. Different employees can accept appointments at the same time.

## Existing administrative RPCs

- create_business_application: creates a pending business application and default records.
- cancel_appointment: customer cancellation authorization.
- review_business: admin-only business approval/rejection/deactivation.
- admin_set_user_blocked: admin-only user blocking.

Appointment insert/cancellation triggers write in-app notifications. Push delivery and scheduled reminders still require APNs/FCM credentials and a server-side delivery job.

## First administrator

The app intentionally has no self-service admin promotion. After the first administrator account is created through Supabase Auth, a project owner must set that profile's is_admin flag from the Supabase SQL editor, matching the Auth user ID:

    update public.profiles
    set is_admin = true
    where id = (select id from auth.users where email = 'ADMIN_EMAIL_HERE');

The Android APK workflow builds the new default app. The iOS build workflow is manual-only and must not be run until an iOS build is explicitly requested.
