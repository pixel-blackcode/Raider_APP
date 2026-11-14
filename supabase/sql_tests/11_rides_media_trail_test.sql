-- =============================================================================
-- Balades enrichies : photo de couverture, itinéraire du chef de convoi.
-- =============================================================================
begin;

select tests.create_user(u) from unnest(array['orga', 'chef', 'retard', 'autre']) u;
select tests.authenticate_as('orga');
select public.create_ride('Trace test', now() + interval '1 day', 'Kinshasa', 'Victoire', 'Kinkole',
                          'public', 'open', p_publish => true,
                          p_start_lat => -4.3317, p_start_lng => 15.3139,
                          p_destination_lat => -4.3986, p_destination_lng => 15.5017);
select tests.ok((select start_lat is not null and destination_lng is not null
                   from public.rides where title = 'Trace test'),
  'départ et arrivée pointés enregistrés');

-- Photo de couverture.
insert into storage.objects (bucket_id, name)
values ('ride-media', tests.ride_id('Trace test') || '/cover-1.jpg');
select tests.ok(public.set_ride_cover(tests.ride_id('Trace test'),
                                      tests.ride_id('Trace test') || '/cover-1.jpg') is null,
  'couverture enregistrée par l''organisatrice');
select tests.throws(
  format($$select public.set_ride_cover(%L, 'ailleurs/x.jpg')$$, tests.ride_id('Trace test')),
  'invalid_input', 'chemin hors du dossier de la balade refusé');
select tests.authenticate_as('autre');
select tests.throws(
  format($$select public.set_ride_cover(%L, null)$$, tests.ride_id('Trace test')),
  'not_allowed', 'un non-gestionnaire ne change pas la couverture');
select tests.throws(
  format($$insert into storage.objects (bucket_id, name) values ('ride-media', %L)$$,
         tests.ride_id('Trace test') || '/pirate.jpg'),
  'row-level security', 'un non-gestionnaire ne dépose pas de photo');
select tests.ok(tests.count_of($$select 1 from storage.objects where bucket_id = 'ride-media'$$) = 1,
  'la couverture d''une balade publique est visible');

-- Itinéraire : seul le chef de convoi trace.
select tests.authenticate_as('chef');
select public.join_ride(tests.ride_id('Trace test'));
select tests.authenticate_as('retard');
select public.join_ride(tests.ride_id('Trace test'));
select tests.authenticate_as('orga');
select public.set_ride_status(tests.ride_id('Trace test'), 'start');
select public.set_convoy_role(tests.ride_id('Trace test'), 'leader', tests.uid('chef'));

select tests.authenticate_as('chef');
select public.set_location_sharing(tests.ride_id('Trace test'), true);
select public.publish_position(tests.ride_id('Trace test'), -4.3317, 15.3139, now() - interval '3 minutes');
reset role;
update public.ride_positions set received_at = now() - interval '1 minute';
select tests.authenticate_as('chef');
select public.publish_position(tests.ride_id('Trace test'), -4.3318, 15.3139, now() - interval '2 minutes');
reset role;
update public.ride_positions set received_at = now() - interval '1 minute';
select tests.authenticate_as('chef');
select public.publish_position(tests.ride_id('Trace test'), -4.3400, 15.3300, now());
select tests.authenticate_as('retard');
select tests.ok(tests.count_of('select 1 from public.ride_trail_points') = 2,
  'le retardataire voit l''itinéraire du chef (points espacés d''au moins 25 m)');
select public.set_location_sharing(tests.ride_id('Trace test'), true);
select public.publish_position(tests.ride_id('Trace test'), -4.30, 15.30, now());
select tests.ok(tests.count_of('select 1 from public.ride_trail_points') = 2,
  'les autres participants ne laissent pas de trace');
select tests.authenticate_as('autre');
select tests.ok(tests.count_of('select 1 from public.ride_trail_points') = 0,
  'un non-participant ne voit pas l''itinéraire');
select tests.throws($$insert into public.ride_trail_points (ride_id, lat, lng, recorded_at)
                      values (tests.ride_id('Trace test'), 0, 0, now())$$,
  'permission denied', 'aucune écriture directe');

-- Fin + 72 h : itinéraire purgé.
select tests.authenticate_as('orga');
select public.set_ride_status(tests.ride_id('Trace test'), 'finish');
select tests.authenticate_as('retard');
select tests.ok(tests.count_of('select 1 from public.ride_trail_points') = 0,
  'après la fin, l''itinéraire n''est plus visible');
reset role;
update public.rides set finished_at = now() - interval '73 hours' where title = 'Trace test';
select private.purge_ride_positions();
select tests.ok((select count(*) from public.ride_trail_points) = 0, 'itinéraire supprimé après 72 h');

rollback;
