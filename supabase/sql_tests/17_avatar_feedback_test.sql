-- =============================================================================
-- Visibilité de la photo de profil ; signalements et suggestions.
-- =============================================================================
begin;

select tests.create_user(u) from unnest(array['motard', 'ami', 'inconnu', 'equipe']) u;
insert into private.platform_admins (user_id) values (tests.uid('equipe'));

select tests.authenticate_as('motard');
select public.create_club('Phoenix Riders', 'Kinshasa', 'public', 'open');
insert into storage.objects (bucket_id, name) values ('avatars', tests.uid('motard') || '/photo.jpg');
select tests.authenticate_as('ami');
select public.join_club(tests.club_id('Phoenix Riders'));

select tests.authenticate_as('inconnu');
select tests.ok(tests.count_of($$select 1 from storage.objects where bucket_id = 'avatars'$$) = 1,
  'par défaut, photo visible de tous');

select tests.authenticate_as('motard');
insert into public.profile_settings (user_id, avatar_visibility) values (tests.uid('motard'), 'clubs');
select tests.authenticate_as('inconnu');
select tests.ok(tests.count_of($$select 1 from storage.objects where bucket_id = 'avatars'$$) = 0,
  '« membres de mes clubs » : invisible pour un inconnu');
select tests.authenticate_as('ami');
select tests.ok(tests.count_of($$select 1 from storage.objects where bucket_id = 'avatars'$$) = 1,
  '« membres de mes clubs » : visible pour un membre');

select tests.authenticate_as('motard');
update public.profile_settings set avatar_visibility = 'nobody' where user_id = tests.uid('motard');
select tests.ok(tests.count_of($$select 1 from storage.objects where bucket_id = 'avatars'$$) = 1,
  'le motard voit toujours sa photo');
select tests.throws($$update public.profile_settings set avatar_visibility = 'tous'$$,
  'check constraint', 'valeur inconnue refusée');
select tests.authenticate_as('ami');
select tests.ok(tests.count_of($$select 1 from storage.objects where bucket_id = 'avatars'$$) = 0,
  '« personne » : invisible même pour un membre');
select tests.authenticate_as('equipe');
select tests.ok(tests.count_of($$select 1 from storage.objects where bucket_id = 'avatars'$$) = 1,
  'l''équipe la voit (modération)');

-- Signalements / suggestions.
select tests.authenticate_as('ami');
select tests.throws($$select public.send_feedback('problem', 'abc')$$, 'invalid_input', 'message trop court');
select tests.throws($$select public.send_feedback('autre', 'Un message valable')$$, 'invalid_input', 'type inconnu');
select public.send_feedback('problem', 'La carte plante quand je pointe l''arrivée', 'b3d9300', 'android');
select public.send_feedback('suggestion', 'Ajouter un mode nuit pour la carte', 'b3d9300', 'android');
select tests.throws($$select * from public.app_feedback$$, 'permission denied', 'table non lisible directement');
select tests.throws($$select * from public.feedback_queue()$$, 'not_allowed', 'file réservée à l''équipe');

select tests.authenticate_as('equipe');
select tests.ok(tests.count_of('select 1 from public.feedback_queue()') = 2, 'l''équipe voit les messages');
select public.mark_feedback_handled((select id from public.feedback_queue() where kind = 'problem'));
select tests.ok(tests.count_of('select 1 from public.feedback_queue()') = 1, 'message traité retiré de la file');
select tests.ok(tests.count_of('select 1 from public.feedback_queue(true)') = 2, 'historique complet');

rollback;
