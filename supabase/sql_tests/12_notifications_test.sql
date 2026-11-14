-- =============================================================================
-- Notifications : créées par le serveur, lues par leur seul destinataire.
-- =============================================================================
begin;

select tests.create_user(u) from unnest(array['orga', 'moto', 'invite', 'bloque']) u;

-- Demande de participation → organisatrice ; décision → demandeur.
select tests.authenticate_as('orga');
select public.create_ride('Notif test', now() + interval '1 day', 'Kinshasa', 'A1', 'B1',
                          'public', 'approval', p_publish => true);
select tests.authenticate_as('moto');
select public.join_ride(tests.ride_id('Notif test'), 'Je peux venir ?');
select tests.authenticate_as('orga');
select tests.ok((select kind = 'ride_join_request' and actionable and actor_name = 'Moto'
                   from public.my_notifications()),
  'l''organisatrice reçoit la demande, à traiter');
select public.decide_ride_request(tests.ride_id('Notif test'), tests.uid('moto'), true);
select tests.ok((select not actionable from public.my_notifications() where kind = 'ride_join_request'),
  'demande traitée : plus d''action proposée');
select tests.authenticate_as('moto');
select tests.ok(tests.count_of($$select 1 from public.my_notifications() where kind = 'ride_request_approved'$$) = 1,
  'le motard apprend que sa demande est acceptée');

-- Invitation.
select tests.authenticate_as('orga');
select public.invite_to_ride(tests.ride_id('Notif test'), tests.uid('invite'));
select tests.authenticate_as('invite');
select tests.ok((select kind = 'ride_invitation' and actionable from public.my_notifications()),
  'invitation reçue, à accepter ou refuser');

-- Démarrage → participants confirmés (pas l'auteur du changement).
select tests.authenticate_as('orga');
select public.set_ride_status(tests.ride_id('Notif test'), 'start');
select tests.authenticate_as('moto');
select tests.ok(tests.count_of($$select 1 from public.my_notifications() where kind = 'ride_started'$$) = 1,
  'les participants sont prévenus du départ');
select tests.authenticate_as('orga');
select tests.ok(tests.count_of($$select 1 from public.my_notifications() where kind = 'ride_started'$$) = 0,
  'pas de notification pour sa propre action');

-- Clubs : demande d'adhésion → administrateurs.
select public.create_club('Club notif', 'Kinshasa', 'public', 'approval');
select tests.authenticate_as('moto');
select public.join_club(tests.club_id('Club notif'), 'Bonjour');
select tests.authenticate_as('orga');
select tests.ok((select actionable from public.my_notifications() where kind = 'club_join_request'),
  'demande d''adhésion reçue par l''administratrice');

-- Communauté et blocage.
select public.create_post(gen_random_uuid(), 'Ma sortie');
select tests.authenticate_as('moto');
select public.add_comment((select id from public.posts where body = 'Ma sortie'), 'Top', gen_random_uuid());
select public.set_reaction((select id from public.posts where body = 'Ma sortie'), 'fire');
select tests.authenticate_as('bloque');
select public.block_user(tests.uid('orga'));
reset role;
-- Un motard bloqué ne peut plus commenter : on simule une réaction ancienne.
insert into public.post_reactions (post_id, user_id, kind)
values ((select id from public.posts where body = 'Ma sortie'), tests.uid('bloque'), 'like');
select tests.authenticate_as('orga');
select tests.ok(tests.count_of($$select 1 from public.my_notifications() where kind in ('post_comment', 'post_reaction')$$) = 2,
  'commentaire et réaction notifiés ; rien venant d''un motard bloqué');

-- Confidentialité et lecture.
select tests.authenticate_as('invite');
select tests.ok(tests.count_of('select 1 from public.notifications') = 1, 'chacun ne voit que ses notifications');
select tests.throws($$insert into public.notifications (user_id, kind) values (tests.uid('invite'), 'post_comment')$$,
  'permission denied', 'aucune notification créée par un client');
select tests.authenticate_as('orga');
select public.mark_notifications_read();
select tests.ok(tests.count_of('select 1 from public.notifications where read_at is null') = 0, 'tout marquer comme lu');
select tests.authenticate_as_anon();
select tests.throws('select count(*) from public.notifications', 'permission denied', 'anonyme : aucun accès');

-- Rétention 90 jours.
reset role;
update public.notifications set created_at = now() - interval '91 days';
select tests.ok(private.purge_notifications() > 0, 'notifications de plus de 90 jours purgées');

rollback;
