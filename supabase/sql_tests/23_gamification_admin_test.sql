-- =============================================================================
-- Mission 11 : distance des balades, badges, défis, meilleure balade du mois,
-- annonces officielles, suspension des comptes, fonctions de l'équipe.
-- =============================================================================
begin;

select tests.create_user(u) from unnest(array['chef', 'jean', 'paul', 'curieux', 'eve']) u;
insert into private.platform_admins (user_id) values (tests.uid('eve'));

-- Une longue balade : Kinshasa → Lubumbashi (≈ 1 560 km à vol d'oiseau).
select tests.authenticate_as('chef');
select public.create_ride('Kin Lushi', now() + interval '1 day', 'Kinshasa', 'Kinshasa', 'Lubumbashi',
  'public', 'open', p_start_lat => -4.3217, p_start_lng => 15.3125,
  p_destination_lat => -11.6609, p_destination_lng => 27.4794, p_publish => true);
select tests.authenticate_as('jean');
select public.join_ride(tests.ride_id('Kin Lushi'));
select tests.authenticate_as('chef');
select public.set_ride_status(tests.ride_id('Kin Lushi'), 'start');
select public.set_ride_status(tests.ride_id('Kin Lushi'), 'finish');
select tests.ok((select distance_km between 1500 and 1600 from public.rides where title = 'Kin Lushi'),
  'distance calculée à la fin de la balade');

-- Badges automatiques.
select tests.authenticate_as('jean');
select tests.ok((select count(*) = 4 from public.badge_awards
                  where user_id = auth.uid() and code in ('first_ride', 'road_100', 'road_500', 'road_1000')),
  'participant : première balade + 3 badges de distance');
select tests.ok(exists (select 1 from public.notifications
                         where kind = 'badge_awarded' and data->>'title' = 'Traversée'),
  'notification du badge');
select tests.ok((select progress = 1 and target = 10 and not earned
                   from public.rider_badges() where code = 'loyal'),
  'pour soi : progression vers le badge suivant');
select tests.authenticate_as('chef');
select tests.ok((select count(*) = 1 from public.rider_badges() where code = 'organizer' and earned),
  'l''organisateur reçoit « Organisateur »');
select tests.authenticate_as('paul');
select tests.ok((select count(*) >= 4 and bool_and(earned) and bool_and(progress is null)
                   from public.rider_badges(tests.uid('jean'))),
  'un autre motard voit les badges obtenus de Jean, sans progression');
select tests.throws($$insert into public.badge_awards (user_id, code) values (auth.uid(), 'pillar')$$,
  'permission denied', 'pas de badge offert à soi-même');

-- Défis : réservés à l'équipe ; distance d'une balade sur la période.
select tests.throws($$select public.admin_create_challenge('Défi pirate', '', 'posts', 1, current_date, current_date)$$,
  'not_allowed', 'seule l''équipe crée des défis');
select tests.authenticate_as('eve');
select tests.throws($$select public.admin_create_challenge('X', '', 'posts', 1, current_date, current_date)$$,
  'invalid_input', 'titre trop court');
select public.admin_create_challenge('Plus longue balade', 'Une balade de 1 000 km ce mois-ci',
  'ride_distance', 1000, current_date - 1, current_date + 20, true);
select public.admin_create_challenge('Deux publications', '', 'posts', 2, current_date - 1, current_date + 20, false);
select tests.authenticate_as('paul');
select tests.ok(exists (select 1 from public.notifications where kind = 'challenge_started'),
  'tous les motards sont prévenus du nouveau défi');
select tests.authenticate_as('jean');
select tests.ok((select completed and progress = 1000 from public.my_challenges() where title = 'Plus longue balade'),
  'défi de distance réussi (balade de la période)');
select tests.ok((select progress = 0 and not completed from public.my_challenges() where title = 'Deux publications'),
  'défi des publications : pas encore');
select public.create_post(gen_random_uuid(), 'Belle sortie !');
select public.create_post(gen_random_uuid(), 'Et une deuxième.');
select tests.ok(exists (select 1 from public.badge_awards where user_id = auth.uid() and code = 'challenge' and title = 'Deux publications'),
  'le badge du défi arrive dès la 2e publication');
select tests.authenticate_as('eve');
select tests.ok((select completed_count = 1 and winners = array['Jean']
                   from public.admin_challenges() where title = 'Plus longue balade'),
  'l''équipe voit qui a réussi le défi');

-- Meilleure balade du mois : badge daté + annonce officielle dans le fil.
select tests.ok((select ride_id = tests.ride_id('Kin Lushi') and not already_awarded
                   from public.admin_ride_of_month_candidates(to_char(now() at time zone 'Africa/Kinshasa', 'YYYY-MM'))
                  limit 1),
  'candidats : la plus longue balade du mois en tête');
select public.admin_award_ride_of_month(tests.ride_id('Kin Lushi'),
  to_char(now() at time zone 'Africa/Kinshasa', 'YYYY-MM'));
select tests.throws(format($$select public.admin_award_ride_of_month(%L, %L)$$, tests.ride_id('Kin Lushi'),
         to_char(now() at time zone 'Africa/Kinshasa', 'YYYY-MM')), 'already_exists', 'une seule par mois');
select tests.authenticate_as('jean');
select tests.ok((select title like 'Meilleure balade du mois · %' and period is not null
                   from public.rider_badges() where code = 'ride_of_month'),
  'badge daté « Meilleure balade du mois · <mois> »');
select tests.authenticate_as('curieux');
select tests.ok((select is_official and body like '%Kin Lushi%' and body like '%Bravo aux 2 motards%'
                   from public.feed_posts() where is_official limit 1),
  'annonce officielle visible dans le fil');
select tests.throws($$select public.admin_publish_announcement('Fausse annonce de l''équipe')$$,
  'not_allowed', 'annonce réservée à l''équipe');

-- Suspension : plus d'écriture, mais lecture et SOS possibles.
select tests.authenticate_as('eve');
select tests.ok((select count(*) = 1 from public.admin_search_users('curi')), 'recherche d''un compte');
select tests.throws(format($$select public.admin_suspend_user(%L, 7, 'x')$$, tests.uid('curieux')),
  'invalid_input', 'raison obligatoire');
select tests.throws(format($$select public.admin_suspend_user(%L, 7, 'Arnaques')$$, tests.uid('eve')),
  'not_allowed', 'pas de suspension d''un administrateur');
select tests.authenticate_as('chef');
select public.create_ride('Sortie test', now() + interval '1 day', 'Kinshasa', 'A1', 'B1', 'public', 'open', p_publish => true);
select tests.authenticate_as('eve');
select public.admin_suspend_user(tests.uid('curieux'), 30, 'Annonces frauduleuses répétées');
select tests.ok((select count(*) = 1 from public.admin_suspended_users()), 'liste des comptes suspendus');
select tests.authenticate_as('curieux');
select tests.ok((select reason = 'Annonces frauduleuses répétées' from public.my_suspension()),
  'le motard voit sa suspension et la raison');
select tests.ok(exists (select 1 from public.notifications where kind = 'account_suspended'),
  'il est prévenu');
select tests.throws($$select public.create_post(gen_random_uuid(), 'Coucou')$$, 'account_suspended',
  'plus de publication');
select tests.throws(format($$select public.join_ride(%L)$$, tests.ride_id('Sortie test')), 'account_suspended',
  'plus de balade');
select tests.ok(tests.count_of('select 1 from public.feed_posts()') > 0, 'la lecture reste possible');
select tests.authenticate_as('eve');
select public.admin_unsuspend_user(tests.uid('curieux'));
select tests.authenticate_as('curieux');
select public.create_post(gen_random_uuid(), 'Je suis de retour');
select tests.ok(exists (select 1 from public.notifications where kind = 'account_restored'),
  'suspension levée : il peut de nouveau publier');

-- Vue d'ensemble de l'équipe.
select tests.throws($$select public.admin_stats()$$, 'not_allowed', 'chiffres réservés à l''équipe');
select tests.authenticate_as('eve');
select tests.ok((select (s->>'riders_total')::int = 5 and (s->>'rides_finished_month')::int = 1
                    and (s->>'active_challenges')::int = 2
                   from public.admin_stats() s),
  'chiffres de la vue d''ensemble');

rollback;
