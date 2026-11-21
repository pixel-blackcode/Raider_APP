-- =============================================================================
-- Rider Group — Migration 0024 : Garage (Mission 10)
-- -----------------------------------------------------------------------------
-- D-69 : chaque motard enregistre ses motos (photo, marque, modèle, année,
-- cylindrée, couleur, plaque, kilométrage), leur historique d'entretien
-- (type, date, km, coût USD/CDF, garage, note, facture) et des rappels (date
-- et/ou kilométrage, répétables). Tout est PRIVÉ, sauf la moto « montrée dans
-- mes alertes SOS » : pendant une alerte SOS active, les motards de la même
-- balade voient son modèle, sa couleur, sa plaque et sa photo.
-- Rappels : notification 7 jours avant la date ou à 300 km du seuil (une par
-- semaine au plus), donc aussi en push (D-68).
-- =============================================================================

create table public.motorcycles (
  id            uuid primary key default gen_random_uuid(),
  owner_id      uuid not null references public.profiles (id) on delete cascade,
  brand         text not null check (char_length(btrim(brand)) between 1 and 40),
  model         text not null check (char_length(btrim(model)) between 1 and 60),
  year          smallint check (year is null or year between 1900 and 2100),
  cc            smallint check (cc is null or cc between 10 and 3000),
  color         text check (color is null or char_length(color) <= 40),
  plate         text check (plate is null or char_length(plate) <= 20),
  odometer_km   integer not null default 0 check (odometer_km between 0 and 2000000),
  is_primary    boolean not null default false,
  show_in_sos   boolean not null default true,
  photo_path    text check (photo_path is null or photo_path like owner_id::text || '/%'),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index motorcycles_owner_idx on public.motorcycles (owner_id);
create unique index motorcycles_one_primary on public.motorcycles (owner_id) where is_primary;

create table public.maintenance_records (
  id            uuid primary key default gen_random_uuid(),
  moto_id       uuid not null references public.motorcycles (id) on delete cascade,
  kind          text not null check (kind in ('oil', 'tires', 'brakes', 'chain', 'service', 'battery', 'other')),
  done_on       date not null,
  odometer_km   integer check (odometer_km is null or odometer_km between 0 and 2000000),
  cost          numeric(12, 2) check (cost is null or cost between 0 and 1000000000),
  currency      text not null default 'USD' check (currency in ('USD', 'CDF')),
  garage        text check (garage is null or char_length(garage) <= 80),
  note          text check (note is null or char_length(note) <= 500),
  invoice_path  text,
  created_at    timestamptz not null default now()
);
create index maintenance_records_moto_idx on public.maintenance_records (moto_id, done_on desc);

create table public.maintenance_reminders (
  id               uuid primary key default gen_random_uuid(),
  moto_id          uuid not null references public.motorcycles (id) on delete cascade,
  kind             text not null check (kind in ('oil', 'tires', 'brakes', 'chain', 'service', 'battery',
                                                  'insurance', 'inspection', 'other')),
  label            text check (label is null or char_length(label) <= 60),
  due_date         date,
  due_km           integer check (due_km is null or due_km between 0 and 2000000),
  interval_km      integer check (interval_km is null or interval_km between 100 and 100000),
  interval_months  smallint check (interval_months is null or interval_months between 1 and 60),
  done_at          timestamptz,
  last_notified_at timestamptz,
  created_at       timestamptz not null default now(),
  check (due_date is not null or due_km is not null)
);
create index maintenance_reminders_moto_idx on public.maintenance_reminders (moto_id) where done_at is null;

alter table public.motorcycles enable row level security;
alter table public.maintenance_records enable row level security;
alter table public.maintenance_reminders enable row level security;
revoke all on public.motorcycles, public.maintenance_records, public.maintenance_reminders
  from anon, authenticated;
grant select on public.motorcycles, public.maintenance_records, public.maintenance_reminders
  to authenticated;

create or replace function private.owns_moto(p_moto_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.motorcycles
                  where id = p_moto_id and owner_id = (select auth.uid()));
$$;
grant execute on function private.owns_moto(uuid) to authenticated;

create policy "motorcycles: les siennes"
  on public.motorcycles for select to authenticated
  using (owner_id = (select auth.uid()));
create policy "maintenance_records: ses motos"
  on public.maintenance_records for select to authenticated
  using (private.owns_moto(moto_id));
create policy "maintenance_reminders: ses motos"
  on public.maintenance_reminders for select to authenticated
  using (private.owns_moto(moto_id));

-- Photos des motos et des factures : garage-media/<propriétaire>/…
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('garage-media', 'garage-media', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- La photo d'une moto montrée dans une alerte SOS active est visible des
-- motards de la balade (D-69).
create or replace function private.can_view_garage_file(p_path text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (storage.foldername(p_path))[1] = (select auth.uid())::text
      or exists (
        select 1 from public.motorcycles m
          join public.sos_alerts a on a.user_id = m.owner_id and a.status = 'active'
         where m.photo_path = p_path and m.show_in_sos and m.is_primary
           and private.can_view_ride_sos(a.ride_id));
$$;
grant execute on function private.can_view_garage_file(text) to authenticated;

create policy "garage-media: le propriétaire, ou la moto d'un SOS actif"
  on storage.objects for select to authenticated
  using (bucket_id = 'garage-media' and private.can_view_garage_file(name));
create policy "garage-media: ajout dans son dossier"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'garage-media'
              and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "garage-media: suppression dans son dossier"
  on storage.objects for delete to authenticated
  using (bucket_id = 'garage-media'
         and (storage.foldername(name))[1] = (select auth.uid())::text);

-- -----------------------------------------------------------------------------
-- Motos
-- -----------------------------------------------------------------------------
create or replace function public.save_motorcycle(
  p_id uuid,
  p_brand text,
  p_model text,
  p_year integer default null,
  p_cc integer default null,
  p_color text default null,
  p_plate text default null,
  p_odometer_km integer default 0,
  p_is_primary boolean default false,
  p_show_in_sos boolean default true
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  saved uuid;
  first_moto boolean;
begin
  if char_length(btrim(coalesce(p_brand, ''))) not between 1 and 40
     or char_length(btrim(coalesce(p_model, ''))) not between 1 and 60
     or (p_year is not null and p_year not between 1900 and 2100)
     or (p_cc is not null and p_cc not between 10 and 3000)
     or coalesce(p_odometer_km, 0) not between 0 and 2000000
     or char_length(coalesce(p_color, '')) > 40
     or char_length(coalesce(p_plate, '')) > 20 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  if p_id is null then
    if (select count(*) from public.motorcycles where owner_id = uid) >= 10 then
      raise exception 'rate_limited' using errcode = 'P0001';
    end if;
    first_moto := not exists (select 1 from public.motorcycles where owner_id = uid);
    if p_is_primary or first_moto then
      update public.motorcycles set is_primary = false where owner_id = uid and is_primary;
    end if;
    insert into public.motorcycles (owner_id, brand, model, year, cc, color, plate, odometer_km,
                                    is_primary, show_in_sos)
    values (uid, btrim(p_brand), btrim(p_model), p_year, p_cc, nullif(btrim(p_color), ''),
            nullif(upper(btrim(p_plate)), ''), coalesce(p_odometer_km, 0),
            p_is_primary or first_moto, coalesce(p_show_in_sos, true))
    returning id into saved;
  else
    if not exists (select 1 from public.motorcycles where id = p_id and owner_id = uid) then
      raise exception 'not_allowed' using errcode = 'P0001';
    end if;
    if p_is_primary then
      update public.motorcycles set is_primary = false
       where owner_id = uid and is_primary and id <> p_id;
    end if;
    update public.motorcycles
       set brand = btrim(p_brand), model = btrim(p_model), year = p_year, cc = p_cc,
           color = nullif(btrim(p_color), ''), plate = nullif(upper(btrim(p_plate)), ''),
           odometer_km = greatest(odometer_km, coalesce(p_odometer_km, 0)),
           is_primary = case when p_is_primary then true else is_primary end,
           show_in_sos = coalesce(p_show_in_sos, show_in_sos),
           updated_at = now()
     where id = p_id
    returning id into saved;
  end if;
  return saved;
end;
$$;

create or replace function public.set_motorcycle_photo(p_id uuid, p_path text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  old text;
begin
  select photo_path into old from public.motorcycles where id = p_id and owner_id = uid;
  if not found then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if p_path is not null and (
       p_path not like uid::text || '/%'
       or not exists (select 1 from storage.objects o
                       where o.bucket_id = 'garage-media' and o.name = p_path)) then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  update public.motorcycles set photo_path = p_path, updated_at = now() where id = p_id;
  return old;
end;
$$;

-- Supprime la moto (entretiens et rappels avec) ; retourne les fichiers à effacer.
create or replace function public.delete_motorcycle(p_id uuid)
returns text[]
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  files text[];
  was_primary boolean;
begin
  select is_primary into was_primary from public.motorcycles where id = p_id and owner_id = uid;
  if not found then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  select array_remove(array_agg(distinct f), null) into files from (
    select photo_path as f from public.motorcycles where id = p_id
    union all select invoice_path from public.maintenance_records where moto_id = p_id) x;
  delete from public.motorcycles where id = p_id;
  if was_primary then
    update public.motorcycles set is_primary = true
     where id = (select id from public.motorcycles where owner_id = uid order by created_at limit 1);
  end if;
  return coalesce(files, '{}');
end;
$$;

-- -----------------------------------------------------------------------------
-- Entretiens
-- -----------------------------------------------------------------------------
create or replace function public.add_maintenance(
  p_moto_id uuid,
  p_kind text,
  p_done_on date,
  p_odometer_km integer default null,
  p_cost numeric default null,
  p_currency text default 'USD',
  p_garage text default null,
  p_note text default null,
  p_invoice_path text default null,
  p_remind_next boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  created uuid;
  next_km integer;
  next_months smallint;
begin
  if not private.owns_moto(p_moto_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if p_kind not in ('oil', 'tires', 'brakes', 'chain', 'service', 'battery', 'other')
     or p_done_on is null or p_done_on > current_date + 1
     or (p_odometer_km is not null and p_odometer_km not between 0 and 2000000)
     or (p_cost is not null and p_cost not between 0 and 1000000000)
     or coalesce(p_currency, 'USD') not in ('USD', 'CDF')
     or char_length(coalesce(p_garage, '')) > 80
     or char_length(coalesce(p_note, '')) > 500
     or (p_invoice_path is not null and (p_invoice_path not like uid::text || '/%'
         or not exists (select 1 from storage.objects o
                         where o.bucket_id = 'garage-media' and o.name = p_invoice_path))) then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  insert into public.maintenance_records (moto_id, kind, done_on, odometer_km, cost, currency,
                                          garage, note, invoice_path)
  values (p_moto_id, p_kind, p_done_on, p_odometer_km, p_cost, coalesce(p_currency, 'USD'),
          nullif(btrim(p_garage), ''), nullif(btrim(p_note), ''), p_invoice_path)
  returning id into created;

  -- Le compteur de la moto avance avec l'entretien saisi.
  if p_odometer_km is not null then
    update public.motorcycles set odometer_km = greatest(odometer_km, p_odometer_km), updated_at = now()
     where id = p_moto_id;
  end if;
  -- Un rappel du même type est considéré comme fait.
  update public.maintenance_reminders set done_at = now()
   where moto_id = p_moto_id and kind = p_kind and done_at is null;
  -- Rappel suivant (valeurs usuelles par type).
  if p_remind_next then
    next_km := case p_kind when 'oil' then 3000 when 'chain' then 1000 when 'tires' then 10000
                           when 'brakes' then 10000 when 'service' then 6000 else null end;
    next_months := case p_kind when 'oil' then 6 when 'service' then 12 when 'battery' then 24
                               when 'brakes' then 12 else null end;
    if next_km is not null or next_months is not null then
      insert into public.maintenance_reminders (moto_id, kind, due_date, due_km, interval_km,
                                                interval_months)
      values (p_moto_id, p_kind,
              case when next_months is not null then p_done_on + make_interval(months => next_months) end,
              case when next_km is not null then coalesce(p_odometer_km,
                     (select odometer_km from public.motorcycles where id = p_moto_id)) + next_km end,
              next_km, next_months);
    end if;
  end if;
  return created;
end;
$$;

create or replace function public.delete_maintenance(p_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.maintenance_records;
begin
  perform private.require_user();
  select * into r from public.maintenance_records where id = p_id;
  if not found or not private.owns_moto(r.moto_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  delete from public.maintenance_records where id = p_id;
  return r.invoice_path;
end;
$$;

-- -----------------------------------------------------------------------------
-- Rappels
-- -----------------------------------------------------------------------------
create or replace function public.add_reminder(
  p_moto_id uuid,
  p_kind text,
  p_label text default null,
  p_due_date date default null,
  p_due_km integer default null,
  p_interval_km integer default null,
  p_interval_months integer default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  created uuid;
begin
  perform private.require_user();
  if not private.owns_moto(p_moto_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if (select count(*) from public.maintenance_reminders
       where moto_id = p_moto_id and done_at is null) >= 30 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  begin
    insert into public.maintenance_reminders (moto_id, kind, label, due_date, due_km, interval_km,
                                              interval_months)
    values (p_moto_id, p_kind, nullif(btrim(p_label), ''), p_due_date, p_due_km, p_interval_km,
            p_interval_months)
    returning id into created;
  exception when check_violation or not_null_violation then
    raise exception 'invalid_input' using errcode = 'P0001';
  end;
  return created;
end;
$$;

-- Fait : le rappel se termine ; s'il est répétable, le suivant est créé.
create or replace function public.complete_reminder(p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.maintenance_reminders;
  km integer;
begin
  perform private.require_user();
  select * into r from public.maintenance_reminders where id = p_id and done_at is null for update;
  if not found or not private.owns_moto(r.moto_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  update public.maintenance_reminders set done_at = now() where id = p_id;
  if r.interval_km is not null or r.interval_months is not null then
    select odometer_km into km from public.motorcycles where id = r.moto_id;
    insert into public.maintenance_reminders (moto_id, kind, label, due_date, due_km, interval_km,
                                              interval_months)
    values (r.moto_id, r.kind, r.label,
            case when r.interval_months is not null
                 then current_date + make_interval(months => r.interval_months) end,
            case when r.interval_km is not null then km + r.interval_km end,
            r.interval_km, r.interval_months);
  end if;
end;
$$;

-- Reporter : +7 jours et/ou +300 km.
create or replace function public.snooze_reminder(p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.maintenance_reminders;
begin
  perform private.require_user();
  select * into r from public.maintenance_reminders where id = p_id and done_at is null;
  if not found or not private.owns_moto(r.moto_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  update public.maintenance_reminders
     set due_date = case when due_date is not null then greatest(due_date, current_date) + 7 end,
         due_km = case when due_km is not null then due_km + 300 end,
         last_notified_at = null
   where id = p_id;
end;
$$;

create or replace function public.delete_reminder(p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.maintenance_reminders;
begin
  perform private.require_user();
  select * into r from public.maintenance_reminders where id = p_id;
  if not found or not private.owns_moto(r.moto_id) then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  delete from public.maintenance_reminders where id = p_id;
end;
$$;

-- -----------------------------------------------------------------------------
-- La moto dans une alerte SOS
-- -----------------------------------------------------------------------------
create or replace function public.sos_motorcycle(p_alert_id uuid)
returns table (brand text, model text, color text, plate text, photo_path text)
language sql
stable
security definer
set search_path = ''
as $$
  select m.brand, m.model, m.color, m.plate, m.photo_path
    from public.sos_alerts a
    join public.motorcycles m on m.owner_id = a.user_id and m.is_primary and m.show_in_sos
   where a.id = p_alert_id
     and a.status = 'active'
     and (a.user_id = (select auth.uid()) or private.can_view_ride_sos(a.ride_id));
$$;

-- -----------------------------------------------------------------------------
-- Notifications de rappel (tâche quotidienne)
-- -----------------------------------------------------------------------------
alter table public.notifications drop constraint notifications_kind_check;
alter table public.notifications add constraint notifications_kind_check check (kind in (
  'ride_join_request', 'ride_joined', 'ride_request_approved',
  'ride_request_rejected', 'ride_removed', 'ride_invitation',
  'ride_locked', 'ride_started', 'ride_finished', 'ride_cancelled',
  'club_join_request', 'club_request_approved', 'club_request_rejected',
  'club_invitation', 'post_comment', 'post_reaction',
  'club_verification_approved', 'club_verification_rejected',
  'club_verification_expiring', 'club_verification_expired',
  'rider_verification_approved', 'rider_verification_rejected',
  'rider_verification_expiring', 'rider_verification_expired',
  'event_coorganizer_invitation', 'event_coorganizer_accepted',
  'event_coorganizer_declined', 'event_cancelled',
  'club_deletion_requested', 'club_deletion_approved', 'club_deletion_rejected',
  'club_deletion_auto', 'shop_suspended', 'shop_restored', 'maintenance_reminder'));

create or replace function private.process_maintenance_reminders()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  r record;
  n integer := 0;
begin
  for r in
    select x.id, x.kind, x.label, x.due_date, x.due_km, m.owner_id, m.brand, m.model,
           m.odometer_km, m.id as moto_id
      from public.maintenance_reminders x
      join public.motorcycles m on m.id = x.moto_id
     where x.done_at is null
       and (x.last_notified_at is null or x.last_notified_at < now() - interval '7 days')
       and ((x.due_date is not null and x.due_date <= current_date + 7)
            or (x.due_km is not null and x.due_km - m.odometer_km <= 300))
  loop
    perform private.notify(r.owner_id, 'maintenance_reminder', null, p_ref => r.id,
      p_data => jsonb_build_object('kind', r.kind, 'label', r.label,
                                   'moto', r.brand || ' ' || r.model, 'moto_id', r.moto_id,
                                   'due_date', r.due_date,
                                   'km_left', case when r.due_km is not null
                                                   then r.due_km - r.odometer_km end));
    update public.maintenance_reminders set last_notified_at = now() where id = r.id;
    n := n + 1;
  end loop;
  return n;
end;
$$;

revoke all on function private.process_maintenance_reminders() from public, anon, authenticated;

grant execute on function
  public.save_motorcycle(uuid, text, text, integer, integer, text, text, integer, boolean, boolean),
  public.set_motorcycle_photo(uuid, text),
  public.delete_motorcycle(uuid),
  public.add_maintenance(uuid, text, date, integer, numeric, text, text, text, text, boolean),
  public.delete_maintenance(uuid),
  public.add_reminder(uuid, text, text, date, integer, integer, integer),
  public.complete_reminder(uuid),
  public.snooze_reminder(uuid),
  public.delete_reminder(uuid),
  public.sos_motorcycle(uuid)
to authenticated;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('rider-maintenance-reminders', '37 7 * * *',
                          'select private.process_maintenance_reminders()');
  end if;
end;
$$;
