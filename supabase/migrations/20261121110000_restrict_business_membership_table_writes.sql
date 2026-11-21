-- Membership writes must go through the guarded join/leave RPCs.
-- The app reads memberships directly, but never writes to this table from the client.
revoke all on table public.business_memberships from anon;
revoke insert, update, delete, truncate, references, trigger
  on table public.business_memberships from authenticated;
grant select on table public.business_memberships to authenticated;
