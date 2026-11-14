-- =============================================================================
-- Événements moto (clubs/regroupements vérifiés, co-organisateurs) et
-- réactualisation des annonces par les motards vérifiés.
-- =============================================================================
begin;

select tests.create_user(u) from unnest(array['chef', 'chef2', 'chef3', 'motard']) u;

select tests.authenticate_as('chef');
select public.create_club('Phoenix Riders', 'Kinshasa', 'public', 'open');
select tests.authenticate_as('chef2');
select public.create_regroupement('Motards de Gombe', 'Kinshasa', 'public', 'open');
select tests.authenticate_as('chef3');
select public.create_club('Petit Club', 'Kinshasa', 'public', 'open');

-- Club non vérifié : pas d'événement.
select tests.authenticate_as('chef');
select tests.throws(
  format($$select public.create_event(%L, gen_random_uuid(), 'Rassemblement', now() + interval '3 days', 'Place', 'Kinshasa')$$,
         tests.club_id('Phoenix Riders')),
  'verification_required', 'un club non vérifié ne crée pas d''événement');

reset role;
update public.clubs set verified_at = now(), verified_until = now() + interval '1 year'
 where name in ('Phoenix Riders', 'Motards de Gombe');

select tests.authenticate_as('motard');
select public.join_club(tests.club_id('Phoenix Riders'));
select tests.throws(
  format($$select public.create_event(%L, gen_random_uuid(), 'Rassemblement', now() + interval '3 days', 'Place', 'Kinshasa')$$,
         tests.club_id('Phoenix Riders')),
  'not_allowed', 'un simple membre ne crée pas d''événement');

select tests.authenticate_as('chef');
select public.create_event(tests.club_id('Phoenix Riders'), '00000000-0000-4000-8000-0000000000e1',
  'Grand rassemblement', now() + interval '3 days', 'Boulevard du 30 Juin', 'Kinshasa',
  'Tous les motards', null, -4.3, 15.3);
select tests.ok(public.create_event(tests.club_id('Phoenix Riders'), '00000000-0000-4000-8000-0000000000e1',
  'Grand rassemblement', now() + interval '3 days', 'Boulevard du 30 Juin', 'Kinshasa')
  = (select id from public.events), 'création idempotente');
select tests.throws(
  format($$select public.create_event(%L, gen_random_uuid(), 'X', now() + interval '3 days', 'Place', 'Kinshasa')$$,
         tests.club_id('Phoenix Riders')),
  'invalid_input', 'titre trop court refusé');

-- Co-organisateurs : vérifiés seulement, ils acceptent.
select tests.throws(
  format($$select public.invite_event_coorganizer(%L, %L)$$,
         (select id from public.events), tests.club_id('Petit Club')),
  'verification_required', 'un club non vérifié ne co-organise pas');
select public.invite_event_coorganizer((select id from public.events), tests.club_id('Motards de Gombe'));
select tests.throws(
  format($$select public.invite_event_coorganizer(%L, %L)$$,
         (select id from public.events), tests.club_id('Motards de Gombe')),
  'already_invited', 'pas de double invitation');

select tests.authenticate_as('chef2');
select tests.ok((select actionable from public.my_notifications()
                  where kind = 'event_coorganizer_invitation'),
  'le responsable invité reçoit une invitation à traiter');
select tests.ok(not (select can_manage from public.list_events()), 'pas encore gestionnaire');
select public.respond_event_coorganizer((select id from public.event_coorganizers), true);
select tests.ok((select can_manage and jsonb_array_length(coorganizers) = 1 from public.list_events()),
  'co-organisateur accepté : gère l''événement');
select public.update_event((select id from public.events), 'Grand rassemblement 2026',
  now() + interval '4 days', 'Boulevard du 30 Juin', 'Kinshasa');
select tests.ok(tests.count_of(format($$select 1 from public.list_events(p_club_id => %L)$$,
                 tests.club_id('Motards de Gombe'))) = 1,
  'l''événement apparaît chez le co-organisateur');

-- Participation.
select tests.authenticate_as('motard');
select tests.ok((select not can_manage from public.list_events()), 'un motard ne gère pas');
select tests.throws(format($$select public.cancel_event(%L)$$, (select id from public.events)),
  'not_allowed', 'un motard n''annule pas');
select public.set_event_attendance((select id from public.events), true);
select public.set_event_attendance((select id from public.events), true);
select tests.ok((select attendee_count = 1 and i_am_going from public.list_events()), 'J''y vais');

-- Annulation : les participants sont prévenus.
select tests.authenticate_as('chef');
select public.cancel_event((select id from public.events));
select tests.authenticate_as('motard');
select tests.ok(exists (select 1 from public.notifications where kind = 'event_cancelled'),
  'participant prévenu de l''annulation');
select tests.ok(tests.count_of('select 1 from public.list_events()') = 0,
  'événement annulé retiré des événements à venir');
select tests.throws(format($$select public.set_event_attendance(%L, true)$$, (select id from public.events)),
  'invalid_state', 'plus de participation après annulation');

-- Réactualisation des annonces.
select public.create_listing(gen_random_uuid(), 'helmet', 'Casque intégral', 'good', 'Kinshasa');
select tests.throws(format($$select public.bump_listing(%L)$$, (select id from public.listings)),
  'verification_required', 'réservé aux motards vérifiés');
reset role;
update public.profiles set verified_at = now(), verified_until = now() + interval '1 year'
 where id = tests.uid('motard');
select tests.authenticate_as('motard');
select tests.throws(format($$select public.bump_listing(%L)$$, (select id from public.listings)),
  'too_frequent', 'une fois par 24 h');
reset role;
update public.listings set bumped_at = now() - interval '2 days';
select tests.authenticate_as('motard');
select public.bump_listing((select id from public.listings));
select tests.ok((select bumped_at > now() - interval '1 minute' and seller_verified
                   from public.search_listings()), 'annonce remontée, vendeur vérifié');
select tests.authenticate_as('chef');
select tests.throws(format($$select public.bump_listing(%L)$$, (select id from public.listings)),
  'not_allowed', 'seul le vendeur réactualise');

-- Découverte : vérifiés en tête.
select tests.ok((select (array_agg(name))[1] <> 'Petit Club'
                   from public.search_clubs('Riders Gombe Club')), 'un club vérifié passe devant');

rollback;
