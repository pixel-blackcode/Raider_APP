-- =============================================================================
-- Corrections de l'audit de sécurité : visibilité des invitations de
-- co-organisation et limites anti-spam des événements.
-- =============================================================================
begin;

select tests.create_user(u) from unnest(array['chef', 'chef2', 'curieux']) u;
select tests.verify_rider(u) from unnest(array['chef', 'chef2']) u;
select tests.authenticate_as('chef');
select public.create_club('Phoenix Riders', 'Kinshasa', 'public', 'open');
select tests.authenticate_as('chef2');
select public.create_club('Lions MC', 'Kinshasa', 'public', 'open');
reset role;
update public.clubs set verified_at = now(), verified_until = now() + interval '1 year';

select tests.authenticate_as('chef');
select public.create_event(tests.club_id('Phoenix Riders'), gen_random_uuid(), 'Rassemblement',
  now() + interval '3 days', 'Place', 'Kinshasa');
select public.invite_event_coorganizer((select id from public.events), tests.club_id('Lions MC'));

-- SEC-03 : invitation en attente invisible pour un motard quelconque.
select tests.authenticate_as('curieux');
select tests.ok(tests.count_of('select 1 from public.event_coorganizers') = 0,
  'invitation en attente invisible pour un motard quelconque');
select tests.authenticate_as('chef2');
select tests.ok(tests.count_of('select 1 from public.event_coorganizers') = 1,
  'visible du responsable du club invité');
select public.respond_event_coorganizer((select id from public.event_coorganizers), true);
select tests.authenticate_as('curieux');
select tests.ok(tests.count_of('select 1 from public.event_coorganizers') = 1,
  'une co-organisation acceptée est publique');

-- SEC-04 : 10 événements par club et par 24 h.
select tests.authenticate_as('chef');
select public.create_event(tests.club_id('Phoenix Riders'), gen_random_uuid(), 'Sortie ' || g,
  now() + interval '3 days', 'Place', 'Kinshasa') from generate_series(2, 10) g;
select tests.throws(
  format($$select public.create_event(%L, gen_random_uuid(), 'Sortie 11', now() + interval '3 days', 'Place', 'Kinshasa')$$,
         tests.club_id('Phoenix Riders')),
  'rate_limited', '11e événement en 24 h refusé');
select tests.ok(public.create_event(tests.club_id('Phoenix Riders'),
  (select client_ref from public.events where title = 'Sortie 10'),
  'Sortie 10', now() + interval '3 days', 'Place', 'Kinshasa') is not null,
  'un renvoi du même événement reste accepté (idempotence)');

rollback;
