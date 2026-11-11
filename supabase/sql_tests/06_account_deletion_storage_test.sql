-- =============================================================================
-- Suppression de compte d'un utilisateur propriétaire de fichiers Storage
-- partagés (logo d'un club qu'il administre). Supabase refuse de supprimer
-- un utilisateur qui possède encore des objets Storage.
-- =============================================================================
begin;

select tests.create_user(u) from unnest(array['olga', 'paul']) u;

select tests.authenticate_as('olga');
select public.create_club('Goma Riders', 'Goma', 'public', 'open');
select tests.authenticate_as('paul');
select public.join_club(tests.club_id('Goma Riders'));
select tests.authenticate_as('olga');
select public.set_club_member_role(tests.club_id('Goma Riders'), tests.uid('paul'), 'admin');

-- paul (administrateur) dépose le logo du club : il en est propriétaire.
select tests.authenticate_as('paul');
insert into storage.objects (bucket_id, name)
values ('club-media', tests.club_id('Goma Riders') || '/logo-1.jpg');
reset role;
select tests.ok(
  (select owner = tests.uid('paul') from storage.objects where name like '%/logo-1.jpg'),
  'le fichier appartient à celui qui l''a déposé');

select tests.authenticate_as('paul');
select public.delete_my_account();

reset role;
select tests.ok(not exists (select 1 from auth.users where email = 'paul@test.local'),
  'suppression réussie malgré un fichier partagé');
select tests.ok(
  (select owner is null and owner_id is null from storage.objects where name like '%/logo-1.jpg'),
  'le logo du club reste en place, sans propriétaire');

-- -----------------------------------------------------------------------------
-- Organisateurs de balades
-- -----------------------------------------------------------------------------
select tests.create_user(u) from unnest(array['quentin', 'rita']) u;
select tests.authenticate_as('quentin');
select public.create_ride('Balade active', now() + interval '1 day', 'Goma', 'A1', 'B1',
                          'public', 'open', p_publish => true);
select public.create_ride('Balade terminée', now() + interval '1 day', 'Goma', 'A1', 'B1',
                          'public', 'open', p_publish => true);
select public.create_ride('Mon brouillon', now() + interval '1 day', 'Goma', 'A1', 'B1',
                          'public', 'open');
select tests.authenticate_as('rita');
select public.join_ride(tests.ride_id('Balade active'));
select public.join_ride(tests.ride_id('Balade terminée'));
select tests.authenticate_as('quentin');
select public.set_ride_status(tests.ride_id('Balade terminée'), 'start');
select public.set_ride_status(tests.ride_id('Balade terminée'), 'finish');

select tests.throws('select public.delete_my_account()', 'organizes_active_rides',
  'suppression refusée tant qu''on organise une balade active avec des inscrits');

select public.set_ride_status(tests.ride_id('Balade active'), 'cancel', 'Départ de l''organisateur');
select public.delete_my_account();

reset role;
select tests.ok(not exists (select 1 from auth.users where email = 'quentin@test.local'),
  'après annulation, la suppression du compte aboutit');
select tests.ok(tests.ride_id('Mon brouillon') is null, 'les brouillons sont supprimés');
select tests.ok(
  (select organizer_id is null and status = 'finished' from public.rides where title = 'Balade terminée')
  and tests.participant_status('Balade terminée', 'rita') = 'confirmed',
  'une balade terminée reste dans l''historique des participants');
select tests.ok(
  (select organizer_id is null and status = 'cancelled' from public.rides where title = 'Balade active'),
  'une balade annulée reste visible avec son motif');

rollback;
