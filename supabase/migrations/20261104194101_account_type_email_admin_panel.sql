alter table public.profiles
  add column if not exists account_type text not null default 'customer',
  add column if not exists email text;
alter table public.profiles
  add constraint profiles_account_type_check
  check (account_type in ('customer','business_owner'));
create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  insert into public.profiles (id, full_name, email, account_type)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), new.email,
    case when new.raw_user_meta_data->>'account_type' = 'business_owner' then 'business_owner' else 'customer' end);
  return new;
end;
$function$;
update public.profiles p set email = u.email from auth.users u where u.id = p.id and p.email is null;
drop policy if exists "admin reads all appointments" on public.appointments;
create policy "admin reads all appointments" on public.appointments for select to authenticated using ((select private.is_admin()));