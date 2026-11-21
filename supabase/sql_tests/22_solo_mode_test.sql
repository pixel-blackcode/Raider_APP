-- =============================================================================
-- Mode solo : proches qui acceptent, trajet, arrivée, retard, demandes de
-- nouvelles, rappel 45 minutes après l'heure prévue, position privée.
-- =============================================================================
begin;

select tests.create_user(u) from unnest(array['jean', 'paul', 'marc', 'curieux']) u;

-- Proches : il faut qu'ils acceptent.
select tests.authenticate_as('jean');
select tests.throws(format('select public.request_solo_contact(%L)', tests.uid('jean')), 'not_allowed',
  'pas soi-même comme proche');
select public.request_solo_contact(tests.uid('paul'));
select public.request_solo_contact(tests.uid('paul'));
select public.request_solo_contact(tests.uid('marc'));
select tests.ok(tests.count_of('select 1 from public.solo_contacts') = 2, 'deux demandes, sans doublon');
select tests.throws(format($$select public.start_solo_trip(array[%L]::uuid[], 30)$$, tests.uid('paul')),
  'not_allowed', 'un proche doit d''abord accepter');

select tests.authenticate_as('paul');
select tests.ok((select actionable from public.my_notifications() where kind = 'solo_contact_request'),
  'la demande se traite depuis la cloche');
select public.respond_solo_contact((select id from public.solo_contacts), true);
select tests.authenticate_as('marc');
select public.respond_solo_contact((select id from public.solo_contacts), false);
select tests.authenticate_as('jean');
select tests.ok((select count(*) = 1 and bool_and(status = 'accepted') from public.my_solo_contacts()),
  'Paul accepté ; le refus de Marc efface la demande');
select tests.ok(exists (select 1 from public.notifications where kind = 'solo_contact_accepted'),
  'Jean est prévenu que Paul a accepté');

-- Départ.
select tests.throws($$select public.start_solo_trip(array[]::uuid[], 30)$$, 'invalid_input', 'au moins un proche');
select tests.throws(format($$select public.start_solo_trip(array[%L]::uuid[], 2)$$, tests.uid('paul')),
  'invalid_input', 'au moins 5 minutes');
select public.start_solo_trip(array[tests.uid('paul')], 30, false, 'Maison');
select tests.throws(format($$select public.start_solo_trip(array[%L]::uuid[], 30)$$, tests.uid('paul')),
  'already_active', 'un seul trajet à la fois');
select tests.throws($$select public.update_solo_location((select id from public.solo_trips), -4.3, 15.3)$$,
  'not_allowed', 'pas de position continue sans l''avoir choisi');

select tests.authenticate_as('paul');
select tests.ok((select data->>'destination' = 'Maison' from public.notifications where kind = 'solo_trip_started'),
  'le proche est prévenu du départ');
select tests.ok((select not mine and display_name = 'Jean' from public.my_solo_trips()), 'le proche voit le trajet');
select tests.authenticate_as('curieux');
select tests.ok(tests.count_of('select 1 from public.solo_trips') = 0
                and tests.count_of('select 1 from public.my_solo_trips()') = 0, 'un autre motard ne voit rien');
select tests.throws($$select public.ask_solo_news((select id from public.solo_trips where true limit 1))$$,
  'not_allowed', 'seuls les proches demandent des nouvelles');

-- Position partagée au choix.
select tests.authenticate_as('jean');
select public.set_solo_sharing((select id from public.solo_trips), true);
select public.update_solo_location((select id from public.solo_trips), -4.32, 15.31, 12);
select tests.authenticate_as('paul');
select tests.ok((select last_lat = -4.32 from public.my_solo_trips()), 'le proche voit la position partagée');

-- Demandes du proche.
select public.ask_solo_news((select id from public.solo_trips), 'position');
select tests.throws($$select public.ask_solo_news((select id from public.solo_trips), 'news')$$,
  'rate_limited', 'une demande toutes les 5 minutes');
select tests.authenticate_as('jean');
select tests.ok(exists (select 1 from public.notifications where kind = 'solo_position_request'),
  'Jean reçoit la demande de position');
select public.send_solo_position((select id from public.solo_trips), -4.33, 15.32);
select tests.authenticate_as('paul');
select tests.ok(exists (select 1 from public.notifications where kind = 'solo_position_shared'),
  'Paul est prévenu de la position envoyée');

-- Retard : 45 minutes sans nouvelles, puis rappel simple.
reset role;
update public.solo_trips set expected_at = now() - interval '1 minute';
select tests.ok(private.process_solo_trips() = 1, 'heure dépassée : traitement');
select tests.authenticate_as('jean');
select tests.ok(exists (select 1 from public.notifications where kind = 'solo_check_in'),
  'Jean : « Êtes-vous bien arrivé ? »');
select tests.authenticate_as('paul');
select tests.ok(exists (select 1 from public.notifications where kind = 'solo_trip_overdue'),
  'Paul : Jean n''a pas confirmé son arrivée');
reset role;
select tests.ok(private.process_solo_trips() = 0, 'pas de doublon');
update public.solo_trips set overdue_at = now() - interval '46 minutes', last_ok_at = null;
select tests.ok(private.process_solo_trips() = 1, '45 minutes sans nouvelles : rappel');
select tests.ok(private.process_solo_trips() = 0, 'un seul rappel');
select tests.authenticate_as('paul');
select tests.ok(exists (select 1 from public.notifications where kind = 'solo_trip_no_news'),
  'Paul reçoit le rappel');

-- « Je vais bien » + 15 minutes, puis arrivée.
select tests.authenticate_as('jean');
select public.solo_im_ok((select id from public.solo_trips), 15);
select tests.ok((select overdue_at is null and expected_at > now() from public.solo_trips),
  'je vais bien : le délai repart');
select public.arrive_solo_trip((select id from public.solo_trips));
select tests.ok((select status = 'arrived' and last_lat is null and not share_location from public.solo_trips),
  'arrivé : trajet clos, position effacée');
select tests.authenticate_as('paul');
select tests.ok(exists (select 1 from public.notifications where kind = 'solo_trip_arrived'),
  'Paul : Jean est bien arrivé');
select tests.ok((select status = 'arrived' from public.my_solo_trips()), 'encore visible quelques heures');
select tests.throws($$select public.ask_solo_news((select id from public.solo_trips))$$,
  'not_allowed', 'plus de demande après l''arrivée');

-- Le proche peut se retirer.
select public.remove_solo_contact((select id from public.solo_contacts));
select tests.ok(tests.count_of('select 1 from public.solo_contacts') = 0, 'le lien est supprimé');

-- Écriture directe interdite.
select tests.authenticate_as('jean');
select tests.throws($$update public.solo_trips set status = 'active'$$, 'permission denied', 'écriture directe interdite');

rollback;
