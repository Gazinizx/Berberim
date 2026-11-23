alter table public.employees
  add column if not exists first_name text not null default '',
  add column if not exists last_name text not null default '',
  add column if not exists phone text not null default '',
  add column if not exists avatar_url text;

update public.employees e
set first_name = coalesce(nullif(btrim(p.first_name), ''), nullif(split_part(btrim(coalesce(e.display_name, '')), ' ', 1), ''), ''),
    last_name = coalesce(nullif(btrim(p.last_name), ''), ''),
    phone = coalesce(nullif(btrim(p.phone), ''), ''),
    avatar_url = p.avatar_url
from public.profiles p
where p.id = e.user_id
  and (e.first_name = '' or e.last_name = '' or e.phone = '' or e.avatar_url is distinct from p.avatar_url);

create or replace function private.sync_employee_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  update public.employees
  set first_name = coalesce(new.first_name, ''),
      last_name = coalesce(new.last_name, ''),
      phone = coalesce(new.phone, ''),
      avatar_url = new.avatar_url,
      display_name = coalesce(nullif(concat_ws(' ', nullif(btrim(new.first_name), ''), nullif(btrim(new.last_name), '')), ''), new.full_name)
  where user_id = new.id;

  return new;
end;
$function$;

drop trigger if exists sync_employee_profile_after_update on public.profiles;
create trigger sync_employee_profile_after_update
after update of first_name, last_name, phone, avatar_url, full_name
on public.profiles
for each row
execute function private.sync_employee_profile();
