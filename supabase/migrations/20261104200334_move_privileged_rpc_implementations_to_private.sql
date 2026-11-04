grant usage on schema private to authenticated;

alter function public.book_appointment(uuid,uuid,uuid,timestamp with time zone,text) set schema private;
alter function public.cancel_appointment(uuid) set schema private;
alter function public.claim_employee_invite(text) set schema private;
alter function public.create_business_application(text,text) set schema private;
alter function public.create_employee_invite(uuid,text) set schema private;
alter function public.get_available_slots(uuid,uuid,uuid,date) set schema private;
alter function public.join_business_by_code(text) set schema private;
alter function public.review_business(uuid,text) set schema private;
alter function public.update_appointment_status(uuid,text) set schema private;
drop function if exists public.admin_review_business(uuid,text);

revoke all on function private.book_appointment(uuid,uuid,uuid,timestamp with time zone,text) from public,anon;
revoke all on function private.cancel_appointment(uuid) from public,anon;
revoke all on function private.claim_employee_invite(text) from public,anon;
revoke all on function private.create_business_application(text,text) from public,anon;
revoke all on function private.create_employee_invite(uuid,text) from public,anon;
revoke all on function private.get_available_slots(uuid,uuid,uuid,date) from public,anon;
revoke all on function private.join_business_by_code(text) from public,anon;
revoke all on function private.review_business(uuid,text) from public,anon;
revoke all on function private.update_appointment_status(uuid,text) from public,anon;
grant execute on function private.book_appointment(uuid,uuid,uuid,timestamp with time zone,text) to authenticated;
grant execute on function private.cancel_appointment(uuid) to authenticated;
grant execute on function private.claim_employee_invite(text) to authenticated;
grant execute on function private.create_business_application(text,text) to authenticated;
grant execute on function private.create_employee_invite(uuid,text) to authenticated;
grant execute on function private.get_available_slots(uuid,uuid,uuid,date) to authenticated;
grant execute on function private.join_business_by_code(text) to authenticated;
grant execute on function private.review_business(uuid,text) to authenticated;
grant execute on function private.update_appointment_status(uuid,text) to authenticated;

create or replace function public.book_appointment(p_business_id uuid,p_employee_id uuid,p_service_id uuid,p_starts_at timestamp with time zone,p_customer_note text default null)
returns uuid language sql security invoker set search_path to ''
as $function$ select private.book_appointment(p_business_id,p_employee_id,p_service_id,p_starts_at,p_customer_note); $function$;
create or replace function public.cancel_appointment(p_appointment_id uuid)
returns void language sql security invoker set search_path to ''
as $function$ select private.cancel_appointment(p_appointment_id); $function$;
create or replace function public.claim_employee_invite(p_code text)
returns uuid language sql security invoker set search_path to ''
as $function$ select private.claim_employee_invite(p_code); $function$;
create or replace function public.create_business_application(p_name text,p_address text default null)
returns uuid language sql security invoker set search_path to ''
as $function$ select private.create_business_application(p_name,p_address); $function$;
create or replace function public.create_employee_invite(p_business_id uuid,p_display_name text)
returns text language sql security invoker set search_path to ''
as $function$ select private.create_employee_invite(p_business_id,p_display_name); $function$;
create or replace function public.get_available_slots(p_business_id uuid,p_employee_id uuid,p_service_id uuid,p_date date)
returns table(slot_start time without time zone) language sql security invoker set search_path to ''
as $function$ select * from private.get_available_slots(p_business_id,p_employee_id,p_service_id,p_date); $function$;
create or replace function public.join_business_by_code(p_code text)
returns uuid language sql security invoker set search_path to ''
as $function$ select private.join_business_by_code(p_code); $function$;
create or replace function public.review_business(p_business_id uuid,p_status text)
returns void language sql security invoker set search_path to ''
as $function$ select private.review_business(p_business_id,p_status); $function$;
create or replace function public.update_appointment_status(p_appointment_id uuid,p_status text)
returns void language sql security invoker set search_path to ''
as $function$ select private.update_appointment_status(p_appointment_id,p_status); $function$;

revoke all on function public.book_appointment(uuid,uuid,uuid,timestamp with time zone,text) from public,anon;
revoke all on function public.cancel_appointment(uuid) from public,anon;
revoke all on function public.claim_employee_invite(text) from public,anon;
revoke all on function public.create_business_application(text,text) from public,anon;
revoke all on function public.create_employee_invite(uuid,text) from public,anon;
revoke all on function public.get_available_slots(uuid,uuid,uuid,date) from public,anon;
revoke all on function public.join_business_by_code(text) from public,anon;
revoke all on function public.review_business(uuid,text) from public,anon;
revoke all on function public.update_appointment_status(uuid,text) from public,anon;
grant execute on function public.book_appointment(uuid,uuid,uuid,timestamp with time zone,text) to authenticated;
grant execute on function public.cancel_appointment(uuid) to authenticated;
grant execute on function public.claim_employee_invite(text) to authenticated;
grant execute on function public.create_business_application(text,text) to authenticated;
grant execute on function public.create_employee_invite(uuid,text) to authenticated;
grant execute on function public.get_available_slots(uuid,uuid,uuid,date) to authenticated;
grant execute on function public.join_business_by_code(text) to authenticated;
grant execute on function public.review_business(uuid,text) to authenticated;
grant execute on function public.update_appointment_status(uuid,text) to authenticated;
