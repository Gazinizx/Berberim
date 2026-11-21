create extension if not exists pg_net with schema extensions;

create table if not exists public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('android', 'ios')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, token)
);

create index if not exists push_tokens_user_id_idx
  on public.push_tokens (user_id);

alter table public.push_tokens enable row level security;

drop policy if exists "Users manage own push tokens" on public.push_tokens;
create policy "Users manage own push tokens"
  on public.push_tokens
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

revoke all on table public.push_tokens from anon;
grant select, insert, update, delete on table public.push_tokens to authenticated;
grant all on table public.push_tokens to service_role;

do $$
begin
  if not exists (
    select 1
    from vault.decrypted_secrets
    where name = 'berberim_push_webhook_secret'
  ) then
    perform vault.create_secret(
      encode(extensions.gen_random_bytes(32), 'hex'),
      'berberim_push_webhook_secret',
      'Shared authentication secret for Berberim database-to-push function calls'
    );
  end if;
end;
$$;

create or replace function public.verify_berberim_push_secret(p_candidate text)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from vault.decrypted_secrets
    where name = 'berberim_push_webhook_secret'
      and decrypted_secret = p_candidate
  );
$$;

revoke all on function public.verify_berberim_push_secret(text)
  from public, anon, authenticated;
grant execute on function public.verify_berberim_push_secret(text)
  to service_role;

create or replace function private.dispatch_push_notification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_secret text;
begin
  select decrypted_secret
    into v_secret
  from vault.decrypted_secrets
  where name = 'berberim_push_webhook_secret'
  limit 1;

  if v_secret is null then
    return new;
  end if;

  perform net.http_post(
    url := 'https://esnrbyegnxykvsghsjjq.supabase.co/functions/v1/send-push-notification',
    body := jsonb_build_object('notification_id', new.id),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-berberim-push-secret', v_secret
    ),
    timeout_milliseconds := 5000
  );

  return new;
exception
  when others then
    raise warning 'Berberim push dispatch enqueue failed: %', sqlerrm;
    return new;
end;
$$;

drop trigger if exists notifications_dispatch_push on public.notifications;
create trigger notifications_dispatch_push
  after insert on public.notifications
  for each row
  execute function private.dispatch_push_notification();

create or replace function private.notify_appointment_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_owner uuid;
  v_employee uuid;
  v_service text;
  v_when text;
begin
  select b.owner_id
    into v_owner
  from public.businesses b
  where b.id = new.business_id;

  select e.user_id
    into v_employee
  from public.employees e
  where e.id = new.employee_id;

  select s.name
    into v_service
  from public.services s
  where s.id = new.service_id;

  v_when := to_char(
    new.starts_at at time zone 'Europe/Istanbul',
    'DD.MM.YYYY HH24:MI'
  );

  if tg_op = 'INSERT' then
    insert into public.notifications(user_id, appointment_id, title, body)
    values (
      new.customer_id,
      new.id,
      'Randevu talebin alındı',
      coalesce(v_service, 'Hizmet') || ' için randevu talebin: ' || v_when
    );

    insert into public.notifications(user_id, appointment_id, title, body)
    values (
      v_owner,
      new.id,
      'Yeni randevu talebi',
      coalesce(v_service, 'Hizmet') || ' için randevu: ' || v_when
    );

    if v_employee is not null and v_employee <> v_owner then
      insert into public.notifications(user_id, appointment_id, title, body)
      values (
        v_employee,
        new.id,
        'Yeni randevu talebi',
        coalesce(v_service, 'Hizmet') || ' için randevu: ' || v_when
      );
    end if;

  elsif old.status is distinct from new.status then
    if new.status = 'confirmed' then
      insert into public.notifications(user_id, appointment_id, title, body)
      values (
        new.customer_id,
        new.id,
        'Randevun onaylandı',
        coalesce(v_service, 'Hizmet') || ' için randevun onaylandı: ' || v_when
      );

    elsif new.status = 'cancelled' then
      insert into public.notifications(user_id, appointment_id, title, body)
      values (
        new.customer_id,
        new.id,
        'Randevu iptal edildi',
        'Randevunuz iptal edildi: ' || v_when
      );

      if v_owner is not null and v_owner <> new.customer_id then
        insert into public.notifications(user_id, appointment_id, title, body)
        values (
          v_owner,
          new.id,
          'Randevu iptal edildi',
          'Bir randevu iptal edildi: ' || v_when
        );
      end if;

      if v_employee is not null
         and v_employee <> v_owner
         and v_employee <> new.customer_id then
        insert into public.notifications(user_id, appointment_id, title, body)
        values (
          v_employee,
          new.id,
          'Randevu iptal edildi',
          'Bir randevu iptal edildi: ' || v_when
        );
      end if;

    elsif new.status = 'completed' then
      insert into public.notifications(user_id, appointment_id, title, body)
      values (
        new.customer_id,
        new.id,
        'Randevun tamamlandı',
        coalesce(v_service, 'Hizmet') || ' randevun tamamlandı: ' || v_when
      );
    end if;
  end if;

  return new;
end;
$function$;
