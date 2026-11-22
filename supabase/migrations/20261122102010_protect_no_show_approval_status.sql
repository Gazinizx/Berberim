-- A special approval request must not be marked completed or no-show before the owner decides.
create or replace function private.update_appointment_status(p_appointment_id uuid, p_status text)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
  if p_status not in ('completed','no_show') then raise exception 'Geçersiz randevu durumu'; end if;

  update public.appointments a
  set status = p_status
  where a.id = p_appointment_id
    and a.status in ('pending','confirmed')
    and a.requires_business_approval = false
    and (
      exists(select 1 from public.businesses b where b.id = a.business_id and b.owner_id = auth.uid())
      or exists(select 1 from public.employees e where e.id = a.employee_id and e.user_id = auth.uid())
      or (select private.is_admin())
    );

  if not found then raise exception 'Randevu bulunamadı veya işlem yetkiniz yok'; end if;
end;
$function$;

revoke all on function private.update_appointment_status(uuid, text) from public, anon;
grant execute on function private.update_appointment_status(uuid, text) to authenticated;
