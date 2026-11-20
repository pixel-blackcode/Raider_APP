-- =============================================================================
-- Rider Group — Migration 0023 : notifications push (Firebase Cloud Messaging)
-- -----------------------------------------------------------------------------
-- D-68 : chaque téléphone connecté enregistre son jeton FCM. Quand une
-- notification de la cloche est créée, ou qu'une alerte SOS est lancée, la
-- base appelle la fonction Edge `send-push`, qui envoie le message aux
-- téléphones concernés, même application fermée.
--   * Le jeton appartient au dernier compte connecté sur le téléphone.
--   * Le texte du message est construit par la fonction Edge (pas de donnée
--     sensible dans la base) ; un SOS part en priorité haute sur un canal
--     sonore dédié.
--   * L'appel sortant est fait par pg_net ; l'URL et le secret partagé sont
--     lus dans Vault (`push_function_url`, `push_shared_secret`). Sans eux
--     (environnement local), rien n'est envoyé et rien n'échoue. La fonction
--     Edge vérifie le secret reçu via push_secret_ok (réservée à
--     service_role) : le secret n'existe qu'à un seul endroit.
-- =============================================================================

create table public.push_tokens (
  token       text primary key check (char_length(token) between 20 and 4096),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  platform    text not null check (platform in ('android', 'ios', 'web')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index push_tokens_user_idx on public.push_tokens (user_id);

alter table public.push_tokens enable row level security;
revoke all on public.push_tokens from anon, authenticated;
grant select on public.push_tokens to authenticated;
create policy "push_tokens: les siens"
  on public.push_tokens for select to authenticated
  using (user_id = (select auth.uid()));

-- Enregistre (ou rattache au compte connecté) le jeton du téléphone.
create or replace function public.register_push_token(p_token text, p_platform text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  if p_token is null or char_length(p_token) not between 20 and 4096
     or p_platform not in ('android', 'ios', 'web') then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  -- Un compte garde au plus 10 téléphones (les plus récents).
  insert into public.push_tokens (token, user_id, platform)
  values (p_token, uid, p_platform)
  on conflict (token) do update
    set user_id = excluded.user_id, platform = excluded.platform, updated_at = now();
  delete from public.push_tokens
   where user_id = uid
     and token not in (select token from public.push_tokens where user_id = uid
                        order by updated_at desc limit 10);
end;
$$;

-- À la déconnexion : le téléphone ne reçoit plus les messages du compte.
create or replace function public.unregister_push_token(p_token text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
begin
  delete from public.push_tokens where token = p_token and user_id = uid;
end;
$$;

-- -----------------------------------------------------------------------------
-- Déclenchement de l'envoi
-- -----------------------------------------------------------------------------
create or replace function private.dispatch_push(p_kind text, p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text;
  v_secret text;
begin
  if to_regprocedure('net.http_post(text,jsonb,jsonb,jsonb,integer)') is null
     or to_regclass('vault.decrypted_secrets') is null then
    return;  -- pas de pg_net / Vault (tests locaux) : rien à envoyer
  end if;
  execute $q$select decrypted_secret from vault.decrypted_secrets where name = 'push_function_url'$q$
     into v_url;
  execute $q$select decrypted_secret from vault.decrypted_secrets where name = 'push_shared_secret'$q$
     into v_secret;
  if v_url is null or v_secret is null then
    return;  -- envoi non configuré
  end if;
  execute 'select net.http_post(url => $1, body => $2, headers => $3, timeout_milliseconds => 5000)'
    using v_url,
          jsonb_build_object('kind', p_kind, 'id', p_id),
          jsonb_build_object('Content-Type', 'application/json', 'x-push-secret', v_secret);
exception when others then
  -- Une panne de l'envoi push ne doit jamais bloquer l'action du motard.
  raise warning 'dispatch_push: %', sqlerrm;
end;
$$;

create or replace function private.push_on_notification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.dispatch_push('notification', new.id);
  return null;
end;
$$;
create trigger notifications_push
  after insert on public.notifications
  for each row execute function private.push_on_notification();

create or replace function private.push_on_sos()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.dispatch_push('sos', new.id);
  return null;
end;
$$;
create trigger sos_alerts_push
  after insert on public.sos_alerts
  for each row execute function private.push_on_sos();

-- Vérification du secret par la fonction Edge (clé service_role uniquement).
create or replace function public.push_secret_ok(p_secret text)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_secret text;
begin
  if to_regclass('vault.decrypted_secrets') is null or p_secret is null then
    return false;
  end if;
  execute $q$select decrypted_secret from vault.decrypted_secrets where name = 'push_shared_secret'$q$
     into v_secret;
  return v_secret is not null and v_secret = p_secret;
end;
$$;
revoke all on function public.push_secret_ok(text) from public, anon, authenticated;
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    grant execute on function public.push_secret_ok(text) to service_role;
  end if;
end;
$$;

revoke all on function
  private.dispatch_push(text, uuid),
  private.push_on_notification(),
  private.push_on_sos()
from public, anon, authenticated;

grant execute on function
  public.register_push_token(text, text),
  public.unregister_push_token(text)
to authenticated;
