-- =============================================================================
-- Rider Group — Migration 0021 : suspension d'une boutique par l'équipe
-- -----------------------------------------------------------------------------
-- D-64 : l'équipe suspend ou rétablit une boutique depuis sa page, avec une
-- raison facultative ; le propriétaire est prévenu. Une boutique suspendue
-- reste visible de son propriétaire et de l'équipe seulement (déjà le cas).
-- list_shops renvoie l'état de suspension pour l'afficher.
-- =============================================================================

drop function public.list_shops(text, uuid, uuid, integer);
create function public.list_shops(
  p_query text default null,
  p_shop_id uuid default null,
  p_owner_id uuid default null,
  p_limit integer default 50
)
returns table (
  id uuid,
  owner_id uuid,
  owner_name text,
  name text,
  description text,
  city text,
  area text,
  phone text,
  logo_path text,
  active boolean,
  listing_count integer,
  suspended boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select s.id, s.owner_id, p.display_name, s.name, s.description, s.city, s.area, s.phone,
         s.logo_path,
         s.suspended_at is null and private.is_verified_rider(s.owner_id),
         (select count(*)::integer from public.listings l
           where l.seller_id = s.owner_id and l.status <> 'sold' and l.moderation = 'visible'),
         s.suspended_at is not null
    from public.shops s
    join public.profiles p on p.id = s.owner_id
   where private.can_view_shop(s.id)
     and (p_shop_id is null or s.id = p_shop_id)
     and (p_owner_id is null or s.owner_id = p_owner_id)
     and (p_query is null or char_length(btrim(p_query)) < 2
          or greatest(private.match_score(p_query, s.name),
                      private.match_score(p_query, s.city)) >= 0.3)
   order by case when p_query is null or char_length(btrim(p_query)) < 2 then 0
                 else private.match_score(p_query, s.name) end desc,
            s.updated_at desc
   limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;

drop function public.set_shop_suspended(uuid, boolean);
create function public.set_shop_suspended(
  p_shop_id uuid, p_suspended boolean, p_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  s public.shops;
begin
  if not private.is_platform_admin() then
    raise exception 'not_allowed' using errcode = 'P0001';
  end if;
  if p_note is not null and char_length(p_note) > 1000 then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  update public.shops set suspended_at = case when p_suspended then now() end, updated_at = now()
   where id = p_shop_id
  returning * into s;
  if not found then
    raise exception 'invalid_input' using errcode = 'P0001';
  end if;
  perform private.notify(s.owner_id,
    case when p_suspended then 'shop_suspended' else 'shop_restored' end, null,
    p_ref => s.id,
    p_data => jsonb_build_object('name', s.name, 'note', nullif(btrim(p_note), '')));
  perform private.log_action(case when p_suspended then 'shop.suspend' else 'shop.restore' end,
                             'shop', p_shop_id, jsonb_build_object('note', p_note, 'by', uid));
end;
$$;

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
  'club_deletion_auto', 'shop_suspended', 'shop_restored'));

grant execute on function
  public.list_shops(text, uuid, uuid, integer),
  public.set_shop_suspended(uuid, boolean, text)
to authenticated;
