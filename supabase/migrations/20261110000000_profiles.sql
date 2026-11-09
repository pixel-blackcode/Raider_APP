-- =============================================================================
-- Rider Group — Migration 0002 : profils (prérequis des clubs)
-- -----------------------------------------------------------------------------
-- Un utilisateur = un compte = un profil. Les responsabilités (propriétaire de
-- club, organisateur...) sont portées par les tables de contexte, jamais par
-- des comptes distincts.
--
-- L'e-mail reste dans auth.users et n'est PAS copié dans profiles
-- (minimisation des données exposées aux autres utilisateurs).
-- =============================================================================

create table public.profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  username      text        not null,
  display_name  text        not null,
  city          text,
  country_code  text        not null default 'CD',
  bio           text,
  avatar_path   text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint profiles_username_format
    check (username ~ '^[a-z0-9_]{3,30}$'),
  constraint profiles_display_name_length
    check (char_length(btrim(display_name)) between 1 and 60),
  constraint profiles_city_length
    check (city is null or char_length(city) <= 80),
  constraint profiles_country_code_format
    check (country_code ~ '^[A-Z]{2}$'),
  constraint profiles_bio_length
    check (bio is null or char_length(bio) <= 500)
);

create unique index profiles_username_key on public.profiles (username);

comment on table public.profiles is
  'Profil public d''un motard. Lecture : utilisateurs connectés. Écriture : le propriétaire uniquement.';

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function private.set_updated_at();

-- -----------------------------------------------------------------------------
-- Création automatique du profil à l'inscription.
-- Les métadonnées d'inscription (username, display_name) sont des suggestions :
-- si elles sont invalides ou déjà prises, une valeur sûre est générée afin de
-- ne jamais bloquer la création du compte.
-- -----------------------------------------------------------------------------
create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  wanted_username text := lower(btrim(coalesce(meta ->> 'username', '')));
  wanted_name text := btrim(coalesce(meta ->> 'display_name', ''));
  fallback_username text := 'rider_' || substr(replace(new.id::text, '-', ''), 1, 12);
begin
  if wanted_username !~ '^[a-z0-9_]{3,30}$'
     or exists (select 1 from public.profiles p where p.username = wanted_username) then
    wanted_username := fallback_username;
  end if;

  if char_length(wanted_name) not between 1 and 60 then
    wanted_name := 'Motard';
  end if;

  begin
    insert into public.profiles (id, username, display_name)
    values (new.id, wanted_username, wanted_name);
  exception when unique_violation then
    -- Course entre deux inscriptions simultanées sur le même pseudonyme.
    insert into public.profiles (id, username, display_name)
    values (new.id, fallback_username, wanted_name);
  end;

  return new;
end;
$$;

revoke all on function private.handle_new_user() from public;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

-- -----------------------------------------------------------------------------
-- Accès
-- -----------------------------------------------------------------------------
alter table public.profiles enable row level security;

revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
-- Seules ces colonnes sont modifiables par le client (id, dates : jamais).
grant update (username, display_name, city, country_code, bio, avatar_path)
  on public.profiles to authenticated;

create policy "profiles: lecture par les utilisateurs connectés"
  on public.profiles for select
  to authenticated
  using (true);

create policy "profiles: modification de son propre profil"
  on public.profiles for update
  to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));
