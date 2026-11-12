-- =============================================================================
-- SOS : déclenchement, destinataires, idempotence, accusés, clôture,
-- rétention (critère 12 : jamais d'alerte « envoyée » sans transmission).
-- =============================================================================
begin;

select tests.create_user(u) from unnest(array['chef', 'moto1', 'moto2', 'dehors']) u;
select tests.authenticate_as('chef');
select public.create_ride('SOS test', now() + interval '1 day', 'Kinshasa', 'A1', 'B1',
                          'public', 'open', p_publish => true);
select tests.authenticate_as('moto1');
select public.join_ride(tests.ride_id('SOS test'));
select tests.authenticate_as('moto2');
select public.join_ride(tests.ride_id('SOS test'));

-- Avant le départ : pas d'alerte.
select tests.authenticate_as('moto1');
select tests.throws(
  format($$select public.raise_sos(%L, 'breakdown', gen_random_uuid())$$, tests.ride_id('SOS test')),
  'ride_not_in_progress', 'pas de SOS hors balade en cours');

select tests.authenticate_as('chef');
select public.set_ride_status(tests.ride_id('SOS test'), 'start');

-- Non-participant : refusé.
select tests.authenticate_as('dehors');
select tests.throws(
  format($$select public.raise_sos(%L, 'accident', gen_random_uuid())$$, tests.ride_id('SOS test')),
  'not_participant', 'un non-participant ne déclenche pas de SOS');

-- Déclenchement avec position de l'appareil.
select tests.authenticate_as('moto1');
select public.raise_sos(tests.ride_id('SOS test'), 'breakdown',
  '11111111-1111-1111-1111-111111111111', 'Pneu crevé', -4.32, 15.31, now(), 12);
select tests.ok(tests.count_of($$select 1 from public.sos_alerts
  where kind = 'breakdown' and status = 'active' and position_source = 'device'$$) = 1,
  'alerte créée avec la position de l''appareil');

-- Idempotence : un renvoi (réseau instable) ne crée pas de doublon.
select public.raise_sos(tests.ride_id('SOS test'), 'breakdown',
  '11111111-1111-1111-1111-111111111111', 'Pneu crevé', -4.32, 15.31, now(), 12);
select tests.ok(tests.count_of('select 1 from public.sos_alerts') = 1,
  'renvoi idempotent : une seule alerte');

-- Repli sur la dernière position du mode Convoi.
select tests.authenticate_as('moto2');
select public.set_location_sharing(tests.ride_id('SOS test'), true);
select public.publish_position(tests.ride_id('SOS test'), -4.40, 15.40, now());
select public.raise_sos(tests.ride_id('SOS test'), 'delay', gen_random_uuid());
select tests.ok(tests.count_of($$select 1 from public.sos_alerts
  where kind = 'delay' and position_source = 'convoy' and lat = -4.40$$) = 1,
  'sans position de l''appareil : dernière position du convoi');
select tests.throws(
  format($$select public.raise_sos(%L, 'accident', gen_random_uuid(), null, 95, 15)$$, tests.ride_id('SOS test')),
  'invalid_input', 'coordonnées invalides refusées');
select tests.throws(
  format($$select public.raise_sos(%L, 'accident', gen_random_uuid(), null, -4.3, null)$$, tests.ride_id('SOS test')),
  'invalid_input', 'latitude sans longitude refusée');

-- Destinataires : participants et organisateur ; pas les autres.
select tests.ok(tests.count_of('select 1 from public.sos_alerts') = 2,
  'un participant voit les alertes de la balade');
select tests.authenticate_as('chef');
select tests.ok(tests.count_of('select 1 from public.sos_alerts') = 2,
  'l''organisateur voit les alertes');
select tests.authenticate_as('dehors');
select tests.ok(tests.count_of('select 1 from public.sos_alerts') = 0,
  'un non-participant ne voit aucune alerte');
select tests.throws(
  format($$select public.acknowledge_sos(%L)$$,
    (select id from public.sos_alerts where client_ref = '11111111-1111-1111-1111-111111111111')),
  'not_allowed', 'un non-participant ne peut pas accuser réception');
select tests.authenticate_as_anon();
select tests.throws('select count(*) from public.sos_alerts', 'permission denied',
  'visiteur anonyme : aucun accès');

-- Accusés de réception.
reset role;
create temp table sos_ids as
  select id, kind from public.sos_alerts;
grant select on sos_ids to authenticated;
select tests.authenticate_as('chef');
select public.acknowledge_sos((select id from sos_ids where kind = 'breakdown'));
select public.acknowledge_sos((select id from sos_ids where kind = 'breakdown'));
select tests.authenticate_as('moto2');
select public.acknowledge_sos((select id from sos_ids where kind = 'breakdown'));
select tests.authenticate_as('moto1');
select tests.ok(tests.count_of('select 1 from public.sos_acknowledgements') = 2,
  'l''auteur voit les deux accusés (sans doublon)');
select tests.throws(
  format($$select public.acknowledge_sos(%L)$$, (select id from sos_ids where kind = 'breakdown')),
  'own_alert', 'on n''accuse pas réception de sa propre alerte');
select tests.throws(
  $$insert into public.sos_alerts (ride_id, user_id, client_ref, kind)
    values (tests.ride_id('SOS test'), tests.uid('moto1'), gen_random_uuid(), 'accident')$$,
  'permission denied', 'aucune écriture directe');
select tests.throws(
  $$update public.sos_alerts set status = 'resolved'$$,
  'permission denied', 'aucune modification directe');

-- Clôture.
select tests.authenticate_as('moto2');
select tests.throws(
  format($$select public.close_sos(%L, 'cancelled')$$, (select id from sos_ids where kind = 'breakdown')),
  'not_allowed', 'un autre participant ne clôt pas l''alerte');
select tests.authenticate_as('chef');
select tests.throws(
  format($$select public.close_sos(%L, 'cancelled')$$, (select id from sos_ids where kind = 'breakdown')),
  'not_allowed', 'l''organisateur ne peut pas annuler à la place de l''auteur');
select public.close_sos((select id from sos_ids where kind = 'breakdown'), 'resolved', 'Réparé sur place');
select tests.throws(
  format($$select public.acknowledge_sos(%L)$$, (select id from sos_ids where kind = 'breakdown')),
  'alert_closed', 'plus d''accusé sur une alerte close');
select tests.authenticate_as('moto2');
select public.close_sos((select id from sos_ids where kind = 'delay'), 'cancelled');
select tests.throws(
  format($$select public.close_sos(%L, 'resolved')$$, (select id from sos_ids where kind = 'delay')),
  'alert_closed', 'une alerte close ne se rouvre pas');
select tests.throws(
  format($$select public.close_sos(%L, 'active')$$, (select id from sos_ids where kind = 'delay')),
  'invalid_input', 'statut de clôture invalide');
select tests.ok(tests.count_of($$select 1 from public.sos_alerts where status = 'active'$$) = 0,
  'les deux alertes sont closes');

-- Limitation : 5 alertes / 10 min.
select tests.authenticate_as('moto1');
select public.raise_sos(tests.ride_id('SOS test'), 'assistance', gen_random_uuid()) from generate_series(1, 4);
select tests.throws(
  format($$select public.raise_sos(%L, 'assistance', gen_random_uuid())$$, tests.ride_id('SOS test')),
  'rate_limited', 'déclenchements répétés limités');

-- Retrait : un participant retiré ne voit plus les alertes.
select tests.authenticate_as('chef');
select public.remove_ride_participant(tests.ride_id('SOS test'), tests.uid('moto2'));
select tests.authenticate_as('moto2');
select tests.ok(tests.count_of($$select 1 from public.sos_alerts where user_id <> tests.uid('moto2')$$) = 0,
  'un participant retiré ne voit plus les alertes des autres');

-- Rétention : coordonnées effacées 72 h après la fin.
select tests.authenticate_as('chef');
select public.set_ride_status(tests.ride_id('SOS test'), 'finish');
reset role;
select tests.ok(private.purge_sos_locations() = 0, 'avant 72 h : coordonnées conservées');
update public.rides set finished_at = now() - interval '73 hours' where title = 'SOS test';
select tests.ok(private.purge_sos_locations() = 2, 'après 72 h : coordonnées effacées');
select tests.ok(tests.count_of('select 1 from public.sos_alerts') = 6,
  'l''historique des alertes est conservé');

-- Après la fin : plus de nouvelle alerte.
select tests.authenticate_as('moto1');
select tests.throws(
  format($$select public.raise_sos(%L, 'accident', gen_random_uuid())$$, tests.ride_id('SOS test')),
  'ride_not_in_progress', 'pas de SOS après la fin');

rollback;
