-- =============================================================================
-- Mode Convoi : partage volontaire, accès aux positions, retrait, fin de
-- balade, rôles de convoi, rétention 72 h (critères 8, 9, 10, 11).
-- =============================================================================
begin;

select tests.create_user(u) from unnest(array['org', 'riri', 'fifi', 'loulou']) u;
select tests.authenticate_as('org');
select public.create_ride('Convoi test', now() + interval '1 day', 'Kinshasa', 'A1', 'B1',
                          'public', 'open', p_publish => true);
select tests.authenticate_as('riri');
select public.join_ride(tests.ride_id('Convoi test'));
select tests.authenticate_as('fifi');
select public.join_ride(tests.ride_id('Convoi test'));

-- Avant le départ : aucune publication.
select tests.authenticate_as('riri');
select public.set_location_sharing(tests.ride_id('Convoi test'), true);
select tests.throws(
  format($$select public.publish_position(%L, -4.3, 15.3, now())$$, tests.ride_id('Convoi test')),
  'ride_not_in_progress', 'pas de publication avant le départ');

select tests.authenticate_as('org');
select public.set_ride_status(tests.ride_id('Convoi test'), 'start');

-- Partage volontaire.
select tests.authenticate_as('fifi');
select tests.throws(
  format($$select public.publish_position(%L, -4.3, 15.3, now())$$, tests.ride_id('Convoi test')),
  'sharing_disabled', 'sans consentement, aucune position n''est publiée');
select tests.authenticate_as('riri');
select public.publish_position(tests.ride_id('Convoi test'), -4.3217, 15.3125, now(), 8, 90, 12);
select tests.ok(true, 'un participant qui partage publie sa position');
select tests.throws(
  format($$select public.publish_position(%L, -4.3, 15.3, now())$$, tests.ride_id('Convoi test')),
  'too_frequent', 'fréquence d''écriture limitée');
select tests.throws(
  format($$select public.publish_position(%L, 95, 15.3, now())$$, tests.ride_id('Convoi test')),
  'invalid_input', 'coordonnées invalides refusées');

-- Acceptation 8 : un non-participant ne voit pas les positions.
select tests.authenticate_as('loulou');
select tests.ok(tests.count_of('select 1 from public.ride_positions') = 0,
  'un non-participant ne voit aucune position');
select tests.throws(
  format($$select public.set_location_sharing(%L, true)$$, tests.ride_id('Convoi test')),
  'not_participant', 'un non-participant ne peut pas partager');
select tests.authenticate_as('fifi');
select tests.ok(tests.count_of('select 1 from public.ride_positions') = 1,
  'un participant confirmé voit les positions partagées');
select tests.authenticate_as('org');
select tests.ok(tests.count_of('select 1 from public.ride_positions') = 1,
  'l''organisateur voit les positions');
select tests.throws(
  $$insert into public.ride_positions (ride_id, user_id, lat, lng, recorded_at)
    values (tests.ride_id('Convoi test'), tests.uid('org'), 0, 0, now())$$,
  'permission denied', 'aucune écriture directe de position');

-- Rôles de convoi.
select public.set_convoy_role(tests.ride_id('Convoi test'), 'leader', tests.uid('riri'));
select public.set_convoy_role(tests.ride_id('Convoi test'), 'sweeper', tests.uid('fifi'));
select tests.throws(
  format($$select public.set_convoy_role(%L, 'leader', %L)$$, tests.ride_id('Convoi test'), tests.uid('loulou')),
  'not_participant', 'chef de convoi : un participant confirmé uniquement');
select tests.authenticate_as('fifi');
select tests.ok(tests.count_of('select 1 from public.ride_role_assignments') = 2,
  'les participants voient les rôles de convoi');
select tests.throws(
  format($$select public.set_convoy_role(%L, 'leader', %L)$$, tests.ride_id('Convoi test'), tests.uid('fifi')),
  'not_allowed', 'un participant ne s''attribue pas de rôle');

-- Acceptation 10 : l'arrêt du partage interrompt la publication.
select tests.authenticate_as('riri');
select public.set_location_sharing(tests.ride_id('Convoi test'), false);
select tests.authenticate_as('fifi');
select tests.ok(tests.count_of('select 1 from public.ride_positions') = 0,
  'arrêt du partage : la position disparaît');
select tests.authenticate_as('riri');
select tests.throws(
  format($$select public.publish_position(%L, -4.3, 15.3, now())$$, tests.ride_id('Convoi test')),
  'sharing_disabled', 'arrêt du partage : plus de publication');

-- Acceptation 9 : un participant exclu perd l'accès.
select public.set_location_sharing(tests.ride_id('Convoi test'), true);
reset role;
update public.ride_positions set received_at = now() - interval '1 minute';
select tests.authenticate_as('fifi');
select public.set_location_sharing(tests.ride_id('Convoi test'), true);
select public.publish_position(tests.ride_id('Convoi test'), -4.33, 15.31, now());
select tests.authenticate_as('org');
select public.remove_ride_participant(tests.ride_id('Convoi test'), tests.uid('fifi'));
select tests.authenticate_as('fifi');
select tests.ok(tests.count_of('select 1 from public.ride_positions') = 0,
  'exclu : plus aucune position visible');
select tests.throws(
  format($$select public.publish_position(%L, -4.3, 15.3, now())$$, tests.ride_id('Convoi test')),
  'not_participant', 'exclu : plus de publication');
reset role;
select tests.ok(
  not exists (select 1 from public.ride_positions where user_id = tests.uid('fifi'))
  and not exists (select 1 from public.ride_role_assignments where user_id = tests.uid('fifi')),
  'exclu : sa position et son rôle de serre-file sont supprimés');

-- Fin de balade : publication arrêtée, positions invisibles, purge à 72 h.
select tests.authenticate_as('riri');
select public.publish_position(tests.ride_id('Convoi test'), -4.31, 15.30, now());
select tests.authenticate_as('org');
select public.set_ride_status(tests.ride_id('Convoi test'), 'finish');
select tests.ok(tests.count_of('select 1 from public.ride_positions') = 0,
  'balade terminée : les positions ne sont plus visibles');
select tests.authenticate_as('riri');
select tests.throws(
  format($$select public.publish_position(%L, -4.3, 15.3, now())$$, tests.ride_id('Convoi test')),
  'ride_not_in_progress', 'balade terminée : publication arrêtée');
reset role;
select tests.ok(private.purge_ride_positions() = 0, 'avant 72 h : rien n''est purgé');
update public.rides set finished_at = now() - interval '73 hours' where title = 'Convoi test';
select tests.ok(private.purge_ride_positions() = 1, 'après 72 h : les positions sont purgées');

rollback;
