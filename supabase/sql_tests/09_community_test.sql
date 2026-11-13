-- =============================================================================
-- Communauté et messagerie : publications, photos, commentaires, réactions,
-- blocage, signalements, modération, conversations privées / groupe / balade.
-- =============================================================================
begin;

select tests.create_user(u) from unnest(array['ana', 'ben', 'cleo', 'dan', 'eve', 'fred']) u;
insert into private.platform_admins (user_id) values (tests.uid('eve'));

-- Club ouvert : ana (propriétaire), ben (membre) ; cleo n'est pas membre.
select tests.authenticate_as('ana');
select public.create_club('Moto Kin', 'Kinshasa', 'public', 'open');
select tests.authenticate_as('ben');
select public.join_club(tests.club_id('Moto Kin'));

-- -----------------------------------------------------------------------------
-- Publications
-- -----------------------------------------------------------------------------
select tests.authenticate_as('ana');
select public.create_post('00000000-0000-4000-8000-000000000001', 'Belle sortie au fleuve !');
select public.create_post('00000000-0000-4000-8000-000000000001', 'Belle sortie au fleuve !');
select tests.ok(tests.count_of($$select 1 from public.posts where body = 'Belle sortie au fleuve !'$$) = 1,
  'publication idempotente (renvoi sans doublon)');
select tests.throws($$select public.create_post(gen_random_uuid(), '   ')$$,
  'invalid_input', 'publication vide refusée');
select tests.throws(
  format($$select public.create_post(gen_random_uuid(), 'x', 'club')$$),
  'invalid_input', 'audience club sans club refusée');

-- Photos : seulement des fichiers réellement envoyés dans son dossier.
insert into storage.objects (bucket_id, name) values ('post-media', tests.uid('ana') || '/p1.jpg');
select tests.throws(
  format($$select public.create_post(gen_random_uuid(), 'photo', p_media_paths => array[%L])$$,
         tests.uid('ana') || '/absente.jpg'),
  'invalid_input', 'photo non envoyée refusée');
select tests.throws(
  format($$select public.create_post(gen_random_uuid(), 'photo', p_media_paths => array[%L])$$,
         tests.uid('ben') || '/p1.jpg'),
  'invalid_input', 'photo d''un autre dossier refusée');
select public.create_post(gen_random_uuid(), 'Avec photo',
  p_media_paths => array[tests.uid('ana') || '/p1.jpg']);
select tests.ok(tests.count_of('select 1 from public.post_media') = 1, 'photo rattachée à la publication');
select tests.throws(
  format($$insert into storage.objects (bucket_id, name) values ('post-media', %L)$$, tests.uid('ben') || '/x.jpg'),
  'row-level security', 'impossible de déposer dans le dossier d''un autre');

-- Publication réservée aux membres du club.
select public.create_post(gen_random_uuid(), 'Réunion du club samedi', 'club', tests.club_id('Moto Kin'));
select tests.authenticate_as('cleo');
select tests.throws(
  format($$select public.create_post(gen_random_uuid(), 'intrus', 'public', %L)$$, tests.club_id('Moto Kin')),
  'not_allowed', 'un non-membre ne publie pas dans l''espace du club');
select tests.ok(tests.count_of($$select 1 from public.posts where audience = 'club'$$) = 0,
  'un non-membre ne voit pas les publications réservées au club');
select tests.ok(tests.count_of('select 1 from public.feed_posts()') = 2,
  'le fil d''un non-membre montre les publications publiques');
select tests.ok(tests.count_of($$select 1 from storage.objects where bucket_id = 'post-media'$$) = 1,
  'la photo d''une publication visible est lisible');
select tests.authenticate_as('ben');
select tests.ok(tests.count_of('select 1 from public.feed_posts()') = 3,
  'un membre voit aussi les publications du club');
select tests.ok(tests.count_of(format('select 1 from public.feed_posts(p_club_id => %L)', tests.club_id('Moto Kin'))) = 1,
  'fil filtré par club');
select tests.ok(tests.count_of(format('select 1 from public.feed_posts(p_post_id => %L)',
  (select id from public.posts where audience = 'club'))) = 1, 'lecture d''une publication par identifiant');
select tests.authenticate_as_anon();
select tests.throws('select count(*) from public.posts', 'permission denied', 'anonyme : aucun accès');

-- -----------------------------------------------------------------------------
-- Commentaires et réactions
-- -----------------------------------------------------------------------------
reset role;
create temp table ids as
  select (select id from public.posts where body = 'Belle sortie au fleuve !') as post_a,
         (select id from public.posts where audience = 'club') as post_club;
grant select on ids to authenticated;

select tests.authenticate_as('ben');
select public.add_comment((select post_a from ids), 'Superbe !', '00000000-0000-4000-8000-0000000000c1');
select public.add_comment((select post_a from ids), 'Superbe !', '00000000-0000-4000-8000-0000000000c1');
select tests.ok(tests.count_of('select 1 from public.post_comments') = 1, 'commentaire idempotent');
select public.set_reaction((select post_a from ids), 'fire');
select public.set_reaction((select post_a from ids), 'like');
select tests.ok(tests.count_of($$select 1 from public.post_reactions where kind = 'like'$$) = 1,
  'une seule réaction par motard (modifiable)');
select tests.authenticate_as('cleo');
select tests.throws(format($$select public.add_comment(%L, 'x', gen_random_uuid())$$, (select post_club from ids)),
  'not_allowed', 'pas de commentaire sur une publication invisible');
select public.set_reaction((select post_a from ids), 'respect');
select tests.ok((select reactions->>'like' = '1' and reactions->>'respect' = '1'
                   from public.feed_posts() where id = (select post_a from ids)),
  'compteurs de réactions par type');
select tests.ok((select comment_count = 1 from public.feed_posts() where id = (select post_a from ids)),
  'compteur de commentaires');
select tests.throws(
  $$insert into public.posts (author_id, body, client_ref) values (tests.uid('cleo'), 'x', gen_random_uuid())$$,
  'permission denied', 'aucune écriture directe');

-- -----------------------------------------------------------------------------
-- Blocage
-- -----------------------------------------------------------------------------
select tests.authenticate_as('cleo');
select public.block_user(tests.uid('ana'));
select tests.ok(tests.count_of('select 1 from public.feed_posts()') = 0,
  'après blocage, les publications de l''autre disparaissent');
select tests.ok(tests.count_of($$select 1 from public.post_reactions where user_id = tests.uid('cleo')$$) = 0,
  'les réactions croisées sont retirées');
select tests.authenticate_as('ana');
select tests.ok(tests.count_of($$select 1 from public.feed_posts(p_author_id => tests.uid('cleo'))$$) = 0,
  'le blocage est réciproque pour la visibilité');
select tests.throws(format($$select public.open_direct_conversation(%L)$$, tests.uid('cleo')),
  'blocked', 'pas de conversation privée entre motards bloqués');
select tests.authenticate_as('cleo');
select tests.ok(tests.count_of('select 1 from public.my_blocked_users()') = 1, 'liste des motards bloqués');
select public.unblock_user(tests.uid('ana'));
select tests.ok(tests.count_of('select 1 from public.feed_posts()') = 2, 'déblocage : contenus de nouveau visibles');

-- -----------------------------------------------------------------------------
-- Signalements et modération
-- -----------------------------------------------------------------------------
select tests.authenticate_as('ben');
select public.report_content('post', (select post_a from ids), 'spam');
select public.report_content('post', (select post_a from ids), 'spam');
select tests.ok(tests.count_of('select 1 from public.content_reports') = 1,
  'un seul signalement ouvert par motard et par contenu');
select tests.authenticate_as('cleo');
select public.report_content('post', (select post_a from ids), 'scam', 'Arnaque ?');
select tests.ok(tests.count_of('select 1 from public.content_reports') = 1,
  'chacun ne voit que ses propres signalements');
select tests.ok(not public.am_i_moderator(), 'un motard ordinaire n''est pas modérateur');
select tests.ok(tests.count_of('select 1 from public.moderation_queue()') = 0,
  'pas de file de modération pour un motard ordinaire');
select tests.throws(format($$select public.moderate_content('post', %L, 'hide')$$, (select post_a from ids)),
  'not_allowed', 'un motard ordinaire ne modère pas');
select tests.authenticate_as('dan');
select public.report_content('post', (select post_a from ids), 'harassment');
select tests.ok(tests.count_of(format('select 1 from public.posts where id = %L', (select post_a from ids))) = 0,
  '3 signalements distincts : publication masquée en attendant la modération');
select tests.authenticate_as('ana');
select tests.ok(tests.count_of(format($$select 1 from public.feed_posts() where id = %L and moderation = 'hidden'$$,
  (select post_a from ids))) = 1, 'l''auteur voit sa publication masquée (avec la mention)');
select tests.throws(format($$select public.add_comment(%L, 'x', gen_random_uuid())$$, (select post_a from ids)),
  'content_hidden', 'pas de commentaire sur un contenu masqué');

select tests.authenticate_as('eve');
select tests.ok(public.am_i_moderator(), 'administrateur de la plateforme : modérateur');
select tests.ok((select report_count = 3 from public.moderation_queue()), 'file de modération regroupée par contenu');
select public.moderate_content('post', (select post_a from ids), 'restore', 'Rien d''illicite');
select tests.ok(tests.count_of($$select 1 from public.content_reports where status = 'dismissed'$$) = 3,
  'rétablir classe les signalements');
select tests.authenticate_as('dan');
select tests.ok(tests.count_of(format('select 1 from public.posts where id = %L', (select post_a from ids))) = 1,
  'publication rétablie visible');

-- Modérateur de club : seulement sur le contenu de son club.
select tests.authenticate_as('ana');
select public.set_club_member_role(tests.club_id('Moto Kin'), tests.uid('ben'), 'moderator');
select tests.authenticate_as('ana');
select public.add_comment((select post_club from ids), 'Hors sujet', gen_random_uuid());
select tests.authenticate_as('ben');
select public.report_content('comment', (select id from public.post_comments where body = 'Hors sujet'), 'spam');
select tests.ok(tests.count_of('select 1 from public.moderation_queue()') = 1,
  'le modérateur du club voit les signalements de son club');
select public.moderate_content('comment', (select id from public.post_comments where body = 'Hors sujet'), 'hide');
select tests.throws(format($$select public.moderate_content('post', %L, 'hide')$$, (select post_a from ids)),
  'not_allowed', 'un modérateur de club ne modère pas hors de son club');
select tests.authenticate_as('fred');
select public.join_club(tests.club_id('Moto Kin'));
select tests.ok(tests.count_of('select 1 from public.post_comments_list((select post_club from ids))') = 0,
  'commentaire masqué invisible pour les autres membres');

-- -----------------------------------------------------------------------------
-- Messagerie privée et de groupe
-- -----------------------------------------------------------------------------
select tests.authenticate_as('ana');
create temp table convs (name text, id uuid);
grant select, insert on convs to authenticated;
insert into convs select 'direct', public.open_direct_conversation(tests.uid('ben'));
select tests.ok(public.open_direct_conversation(tests.uid('ben')) = (select id from convs where name = 'direct'),
  'une seule conversation privée par paire');
select public.send_message((select id from convs where name = 'direct'), 'Salut Ben', '00000000-0000-4000-8000-0000000000a1');
select public.send_message((select id from convs where name = 'direct'), 'Salut Ben', '00000000-0000-4000-8000-0000000000a1');
select tests.ok(tests.count_of('select 1 from public.messages') = 1, 'message idempotent');
select tests.authenticate_as('ben');
select tests.ok((select unread_count = 1 and title = 'Ana' from public.my_conversations()),
  'non-lu et titre de la conversation privée');
select public.mark_conversation_read((select id from convs where name = 'direct'));
select tests.ok((select unread_count = 0 from public.my_conversations()), 'lecture marquée');
select tests.authenticate_as('cleo');
select tests.ok(tests.count_of('select 1 from public.messages') = 0, 'un tiers ne lit pas la conversation');
select tests.throws(
  format($$select public.send_message(%L, 'intrus', gen_random_uuid())$$, (select id from convs where name = 'direct')),
  'conversation_not_found', 'un tiers n''écrit pas dans la conversation');
select tests.authenticate_as('ben');
select public.block_user(tests.uid('ana'));
select tests.throws(
  format($$select public.send_message(%L, 'x', gen_random_uuid())$$, (select id from convs where name = 'direct')),
  'blocked', 'pas de message vers un motard bloqué');
select public.unblock_user(tests.uid('ana'));

select tests.authenticate_as('ana');
insert into convs select 'group', public.create_group_conversation('Sortie dimanche',
  array[tests.uid('ben'), tests.uid('dan')]);
select public.send_message((select id from convs where name = 'group'), 'RDV 8h', gen_random_uuid());
select tests.authenticate_as('dan');
select tests.ok(tests.count_of(format('select 1 from public.conversation_messages(%L)',
  (select id from convs where name = 'group'))) = 1, 'un membre du groupe lit les messages');
select tests.throws(format($$select public.remove_conversation_member(%L, %L)$$,
  (select id from convs where name = 'group'), tests.uid('ben')),
  'not_allowed', 'seul le créateur retire un membre');
select public.remove_conversation_member((select id from convs where name = 'group'), tests.uid('dan'));
select tests.ok(tests.count_of('select 1 from public.messages') = 0, 'après avoir quitté le groupe : plus d''accès');

-- -----------------------------------------------------------------------------
-- Discussion de balade : accès dérivé de la participation
-- -----------------------------------------------------------------------------
select tests.authenticate_as('ana');
select public.create_ride('Balade discussion', now() + interval '1 day', 'Kinshasa', 'A1', 'B1',
                          'public', 'open', p_publish => true);
select tests.authenticate_as('fred');
select public.join_ride(tests.ride_id('Balade discussion'));
insert into convs select 'ride', public.open_ride_conversation(tests.ride_id('Balade discussion'));
select public.send_message((select id from convs where name = 'ride'), 'Je serai là', gen_random_uuid());
select tests.authenticate_as('ana');
select tests.ok(tests.count_of(format('select 1 from public.conversation_messages(%L)',
  (select id from convs where name = 'ride'))) = 1, 'l''organisatrice lit la discussion de balade');
select tests.authenticate_as('cleo');
select tests.throws(format($$select public.open_ride_conversation(%L)$$, tests.ride_id('Balade discussion')),
  'not_participant', 'un non-participant n''ouvre pas la discussion');
select tests.authenticate_as('ana');
select public.remove_ride_participant(tests.ride_id('Balade discussion'), tests.uid('fred'));
select tests.authenticate_as('fred');
select tests.ok(tests.count_of('select 1 from public.messages') = 0,
  'un participant retiré perd l''accès à la discussion');
select tests.throws(
  format($$select public.send_message(%L, 'encore', gen_random_uuid())$$, (select id from convs where name = 'ride')),
  'conversation_not_found', 'un participant retiré ne peut plus écrire');

-- Suppression de sa publication : chemins des photos renvoyés pour nettoyage.
select tests.authenticate_as('ana');
select tests.ok(
  (select public.delete_post((select id from public.posts where body = 'Avec photo')))
    = array[tests.uid('ana') || '/p1.jpg'],
  'suppression : chemins des photos à effacer');
select tests.authenticate_as('ben');
select tests.throws(format($$select public.delete_post(%L)$$, (select post_a from ids)),
  'not_allowed', 'on ne supprime pas la publication d''un autre');

rollback;
