-- =============================================================================
-- Balades : création, visibilité, modes d'adhésion, machine à états,
-- verrouillage, capacité, retraits, balades de club, PostGIS.
-- Couvre notamment les critères d'acceptation 6 et 7 du cahier des charges.
-- =============================================================================
begin;

select tests.create_user(u)
  from unnest(array['alice', 'bob', 'carol', 'dave', 'eve', 'mallory', 'zoe']) u;

select tests.authenticate_as('alice');
select public.create_club('Kin Riders', 'Kinshasa', 'public', 'approval');
reset role;
-- bob est membre du club (insertion directe pour la préparation).
insert into public.club_members (club_id, user_id) values (tests.club_id('Kin Riders'), tests.uid('bob'));

-- -----------------------------------------------------------------------------
-- Création et validation
-- -----------------------------------------------------------------------------
select tests.authenticate_as('alice');
select public.create_ride(
  'Tour du fleuve', now() + interval '1 day', 'Kinshasa', 'Rond-point Victoire', 'Kinkole',
  'public', 'open', p_start_lat => -4.3317, p_start_lng => 15.3139, p_publish => true,
  p_difficulty => 'easy', p_recommended_bike_types => array['roadster', 'trail']);
select tests.ok(
  tests.ride_state('Tour du fleuve') = 'published'
  and tests.participant_status('Tour du fleuve', 'alice') = 'confirmed'
  and (select participant_count = 1 and start_point is not null
         from public.rides where title = 'Tour du fleuve'),
  'balade publiée ; l''organisateur est participant confirmé ; point PostGIS calculé');

select public.create_ride(
  'Lubumbashi – Likasi', now() + interval '2 days', 'Lubumbashi', 'Place de la Poste', 'Likasi',
  'public', 'open', p_timezone => 'Africa/Lubumbashi',
  p_start_lat => -11.6609, p_start_lng => 27.4794, p_publish => true);
select tests.ok(
  (select timezone = 'Africa/Lubumbashi' from public.rides where title = 'Lubumbashi – Likasi'),
  'fuseau horaire de Lubumbashi (UTC+2) accepté');

select tests.throws(
  $$select public.create_ride('Trop tard', now() - interval '1 hour', 'Kinshasa', 'A1', 'B1',
                              'public', 'open', p_publish => true)$$,
  'start_in_past', 'publication refusée pour une date passée');
select tests.throws(
  $$select public.create_ride('Ab', now() + interval '1 day', 'Kinshasa', 'A1', 'B1', 'public', 'open')$$,
  'invalid_input', 'titre trop court refusé');
select tests.throws(
  $$select public.create_ride('Fuseau faux', now() + interval '1 day', 'Kinshasa', 'A1', 'B1',
                              'public', 'open', p_timezone => 'Afrique/Nulle-part')$$,
  'invalid_input', 'fuseau horaire inconnu refusé');
select tests.throws(
  $$select public.create_ride('Club sans club', now() + interval '1 day', 'Kinshasa', 'A1', 'B1',
                              'club', 'open')$$,
  'invalid_input', 'une balade de club exige un club');
select tests.throws(
  format($$select public.create_ride('Publique avec club', now() + interval '1 day', 'Kinshasa',
                                     'A1', 'B1', 'public', 'open', p_club_id => %L)$$,
         tests.club_id('Kin Riders')),
  'invalid_input', 'une balade publique ne peut pas être rattachée à un club');
select tests.throws(
  $$select public.create_ride('Vélo', now() + interval '1 day', 'Kinshasa', 'A1', 'B1',
                              'public', 'open', p_recommended_bike_types => array['velo'])$$,
  'invalid_input', 'type de moto inconnu refusé');
select tests.throws(
  $$select public.create_ride('Solo', now() + interval '1 day', 'Kinshasa', 'A1', 'B1',
                              'public', 'open', p_max_participants => 1)$$,
  'invalid_input', 'capacité minimale de 2 participants');
select tests.throws(
  $$select public.create_ride('Coordonnées', now() + interval '1 day', 'Kinshasa', 'A1', 'B1',
                              'public', 'open', p_start_lat => 120, p_start_lng => 15)$$,
  'invalid_input', 'coordonnées invalides refusées');

select tests.authenticate_as('bob');
select tests.throws(
  format($$select public.create_ride('Balade du club par bob', now() + interval '1 day', 'Kinshasa',
                                     'A1', 'B1', 'club', 'open', p_club_id => %L)$$,
         tests.club_id('Kin Riders')),
  'not_allowed', 'un simple membre ne crée pas de balade au nom du club');

-- -----------------------------------------------------------------------------
-- Brouillons
-- -----------------------------------------------------------------------------
select tests.authenticate_as('alice');
select public.create_ride('Brouillon secret', now() + interval '3 days', 'Kinshasa', 'A1', 'B1',
                          'public', 'open');
select tests.ok(tests.ride_state('Brouillon secret') = 'draft', 'création en brouillon');

select tests.authenticate_as('bob');
select tests.ok(tests.count_of($$select 1 from public.rides where title = 'Brouillon secret'$$) = 0,
  'un brouillon est invisible pour les autres');
select tests.throws(format('select public.join_ride(%L)', tests.ride_id('Brouillon secret')),
  'ride_not_found', 'impossible de rejoindre un brouillon');
select tests.throws(format('select public.delete_ride_draft(%L)', tests.ride_id('Brouillon secret')),
  'not_allowed', 'seul l''organisateur supprime son brouillon');

select tests.authenticate_as('alice');
select tests.throws(format($$select public.set_ride_status(%L, 'cancel')$$, tests.ride_id('Brouillon secret')),
  'invalid_transition', 'un brouillon se supprime, il ne s''annule pas');
select tests.throws(format('select public.delete_ride_draft(%L)', tests.ride_id('Tour du fleuve')),
  'ride_not_editable', 'une balade publiée ne peut pas être supprimée (seulement annulée)');
select public.delete_ride_draft(tests.ride_id('Brouillon secret'));
select tests.ok(tests.ride_id('Brouillon secret') is null, 'brouillon supprimé');

-- -----------------------------------------------------------------------------
-- Acceptation 6 : l'organisateur choisit libre, approbation ou invitation.
-- -----------------------------------------------------------------------------
-- Libre
select tests.authenticate_as('bob');
select tests.ok(public.join_ride(tests.ride_id('Tour du fleuve')) = 'joined',
  'adhésion libre : participation immédiate');
select tests.throws(format('select public.join_ride(%L)', tests.ride_id('Tour du fleuve')),
  'already_participant', 'pas de double participation');

-- Approbation
select tests.authenticate_as('alice');
select public.create_ride('Sortie sur approbation', now() + interval '1 day', 'Kinshasa',
                          'Gare centrale', 'Zongo', 'public', 'approval', p_publish => true);
select tests.authenticate_as('carol');
select tests.ok(public.join_ride(tests.ride_id('Sortie sur approbation'), 'Je roule en trail') = 'requested',
  'approbation : demande en attente');
select tests.ok(tests.participant_status('Sortie sur approbation', 'carol') = 'pending', 'statut pending');
select tests.ok(
  tests.count_of($$select 1 from public.ride_participants where status = 'pending'$$) = 1,
  'le demandeur voit sa demande');
select tests.authenticate_as('dave');
select tests.ok(
  tests.count_of($$select 1 from public.ride_participants where status = 'pending'$$) = 0,
  'un tiers ne voit pas les demandes');
select tests.throws(
  format('select public.decide_ride_request(%L, %L, true)',
         tests.ride_id('Sortie sur approbation'), tests.uid('carol')),
  'not_allowed', 'un tiers ne peut pas approuver');
select tests.authenticate_as('alice');
select public.decide_ride_request(tests.ride_id('Sortie sur approbation'), tests.uid('carol'), true);
select tests.ok(tests.participant_status('Sortie sur approbation', 'carol') = 'confirmed',
  'l''organisateur approuve la demande');

-- Invitation (balade privée)
select public.create_ride('Sortie privée', now() + interval '1 day', 'Kinshasa', 'Ma maison', 'Mbanza-Ngungu',
                          'private', 'invite_only', p_publish => true,
                          p_start_lat => -4.30, p_start_lng => 15.30);
select tests.authenticate_as('dave');
select tests.ok(tests.count_of($$select 1 from public.rides where title = 'Sortie privée'$$) = 0,
  'une balade privée est invisible sans invitation');
select tests.throws(format('select public.join_ride(%L)', tests.ride_id('Sortie privée')),
  'ride_not_found', 'impossible de rejoindre une balade privée par son identifiant');
select tests.authenticate_as('alice');
select public.invite_to_ride(tests.ride_id('Sortie privée'), tests.uid('dave'));
select tests.authenticate_as('dave');
select tests.ok(tests.count_of($$select 1 from public.rides where title = 'Sortie privée'$$) = 1,
  'l''invité voit la balade privée');
select public.respond_to_ride_invitation(
  (select id from public.ride_invitations where invitee_id = tests.uid('dave')), true);
select tests.ok(tests.participant_status('Sortie privée', 'dave') = 'confirmed',
  'invitation acceptée : participant confirmé');

-- Invitation obligatoire sur une balade publique
select tests.authenticate_as('alice');
select public.create_ride('Publique sur invitation', now() + interval '1 day', 'Kinshasa', 'A1', 'B1',
                          'public', 'invite_only', p_publish => true);
select tests.authenticate_as('bob');
select tests.throws(format('select public.join_ride(%L)', tests.ride_id('Publique sur invitation')),
  'invitation_required', 'mode invitation : adhésion directe refusée');

-- -----------------------------------------------------------------------------
-- Acceptation 7 : une balade verrouillée bloque les nouvelles adhésions.
-- -----------------------------------------------------------------------------
select tests.authenticate_as('mallory');
select public.join_ride(tests.ride_id('Sortie sur approbation'));   -- demande en attente

select tests.authenticate_as('alice');
select public.set_ride_status(tests.ride_id('Tour du fleuve'), 'lock');
select public.set_ride_status(tests.ride_id('Sortie sur approbation'), 'lock');
select tests.ok(tests.ride_state('Tour du fleuve') = 'locked+locked', 'balade verrouillée');
select tests.ok(tests.participant_status('Tour du fleuve', 'bob') = 'confirmed',
  'le verrouillage ne retire pas les participants confirmés');

select tests.authenticate_as('eve');
select tests.throws(format('select public.join_ride(%L)', tests.ride_id('Tour du fleuve')),
  'ride_not_joinable', 'verrouillée : adhésion libre refusée');
select tests.throws(format('select public.join_ride(%L)', tests.ride_id('Sortie sur approbation')),
  'ride_not_joinable', 'verrouillée : nouvelle demande refusée');

select tests.authenticate_as('alice');
select tests.throws(
  format('select public.decide_ride_request(%L, %L, true)',
         tests.ride_id('Sortie sur approbation'), tests.uid('mallory')),
  'ride_not_joinable', 'verrouillée : même l''approbation d''une demande est refusée');
select public.invite_to_ride(tests.ride_id('Tour du fleuve'), tests.uid('eve'));
select tests.authenticate_as('eve');
select tests.throws(
  format('select public.respond_to_ride_invitation(%L, true)',
         (select id from public.ride_invitations where invitee_id = tests.uid('eve'))),
  'ride_not_joinable', 'une invitation ne contourne pas le verrouillage');

select tests.authenticate_as('alice');
select public.set_ride_status(tests.ride_id('Tour du fleuve'), 'unlock');
select tests.authenticate_as('eve');
select public.respond_to_ride_invitation(
  (select id from public.ride_invitations where invitee_id = tests.uid('eve')), true);
select tests.ok(tests.participant_status('Tour du fleuve', 'eve') = 'confirmed',
  'déverrouillée : l''invitation peut être acceptée');

-- Départ d'une balade verrouillée : en cours ET adhésions fermées.
select tests.authenticate_as('alice');
select public.set_ride_status(tests.ride_id('Sortie sur approbation'), 'start');
select tests.ok(tests.ride_state('Sortie sur approbation') = 'in_progress+locked',
  'une balade verrouillée démarre verrouillée');
select tests.authenticate_as('zoe');
select tests.throws(format('select public.join_ride(%L)', tests.ride_id('Sortie sur approbation')),
  'ride_not_joinable', 'en cours et verrouillée : adhésion refusée');
select tests.authenticate_as('alice');
select public.set_ride_status(tests.ride_id('Sortie sur approbation'), 'unlock');
select tests.ok(tests.ride_state('Sortie sur approbation') = 'in_progress',
  'déverrouillage pendant la balade');
select tests.authenticate_as('zoe');
select tests.ok(public.join_ride(tests.ride_id('Sortie sur approbation')) = 'requested',
  'en cours non verrouillée : demande possible');
select tests.authenticate_as('alice');
select public.set_ride_status(tests.ride_id('Sortie sur approbation'), 'lock');
select tests.ok(tests.ride_state('Sortie sur approbation') = 'in_progress+locked',
  'verrouillage pendant la balade');

-- -----------------------------------------------------------------------------
-- Machine à états : transitions interdites et droits
-- -----------------------------------------------------------------------------
select tests.throws(format($$select public.set_ride_status(%L, 'finish')$$, tests.ride_id('Tour du fleuve')),
  'invalid_transition', 'publiée → terminée interdit');
select tests.throws(format($$select public.set_ride_status(%L, 'publish')$$, tests.ride_id('Tour du fleuve')),
  'invalid_transition', 'publiée → publiée interdit');
select tests.throws(format($$select public.set_ride_status(%L, 'unlock')$$, tests.ride_id('Tour du fleuve')),
  'invalid_transition', 'déverrouiller une balade non verrouillée interdit');
select tests.throws(format($$select public.set_ride_status(%L, 'teleport')$$, tests.ride_id('Tour du fleuve')),
  'invalid_transition', 'action inconnue refusée');

select tests.authenticate_as('bob');
select tests.throws(format($$select public.set_ride_status(%L, 'lock')$$, tests.ride_id('Tour du fleuve')),
  'not_allowed', 'un participant ne change pas le statut');
select tests.throws(
  $$update public.rides set status = 'finished' where title = 'Tour du fleuve'$$,
  'permission denied', 'le statut n''est pas modifiable directement');

select tests.authenticate_as('alice');
select public.set_ride_status(tests.ride_id('Sortie sur approbation'), 'finish');
select tests.ok(tests.ride_state('Sortie sur approbation') = 'finished', 'balade terminée');
select tests.ok(tests.participant_status('Sortie sur approbation', 'zoe') = 'rejected'
                and tests.participant_status('Sortie sur approbation', 'mallory') = 'rejected',
  'fin de balade : demandes en attente closes');
select tests.throws(format($$select public.set_ride_status(%L, 'cancel')$$, tests.ride_id('Sortie sur approbation')),
  'invalid_transition', 'une balade terminée ne peut plus être annulée');
select tests.throws(format($$select public.set_ride_status(%L, 'start')$$, tests.ride_id('Sortie sur approbation')),
  'invalid_transition', 'une balade terminée ne redémarre pas');
select tests.throws(
  $$update public.rides set title = 'Nouveau titre' where title = 'Sortie sur approbation'$$,
  'ride_not_editable', 'une balade terminée n''est plus modifiable');

select public.set_ride_status(tests.ride_id('Publique sur invitation'), 'cancel', 'Pluie annoncée');
select tests.ok(
  (select status = 'cancelled' and cancellation_reason = 'Pluie annoncée'
     from public.rides where title = 'Publique sur invitation'),
  'annulation avec motif');

-- -----------------------------------------------------------------------------
-- Modifications directes par l'organisateur
-- -----------------------------------------------------------------------------
select tests.ok(
  tests.rows_affected($$update public.rides set description = 'Pause à Maluku', difficulty = 'moderate'
                         where title = 'Tour du fleuve'$$) = 1,
  'l''organisateur modifie une balade publiée');
select tests.throws(
  $$update public.rides set starts_at = now() - interval '1 hour' where title = 'Tour du fleuve'$$,
  'start_in_past', 'date de départ passée refusée');
select tests.throws(
  $$update public.rides set max_participants = 2 where title = 'Tour du fleuve'$$,
  'capacity_below_participants', 'capacité inférieure au nombre de participants refusée');
select tests.throws(
  $$update public.rides set timezone = 'Mars/Olympus' where title = 'Tour du fleuve'$$,
  'invalid_input', 'fuseau horaire inconnu refusé à la modification');
select tests.throws(
  format($$update public.rides set organizer_id = %L where title = 'Tour du fleuve'$$, tests.uid('bob')),
  'permission denied', 'l''organisateur n''est pas modifiable');
select tests.throws(
  $$update public.rides set participant_count = 99 where title = 'Tour du fleuve'$$,
  'permission denied', 'le compteur n''est pas modifiable');

select tests.authenticate_as('bob');
select tests.ok(
  tests.rows_affected($$update public.rides set title = 'Piraté' where title = 'Tour du fleuve'$$) = 0,
  'un participant ne modifie pas la balade');

-- -----------------------------------------------------------------------------
-- Capacité
-- -----------------------------------------------------------------------------
select tests.authenticate_as('alice');
select public.create_ride('Petite sortie', now() + interval '1 day', 'Kinshasa', 'A1', 'B1',
                          'public', 'open', p_max_participants => 2, p_publish => true);
select tests.authenticate_as('bob');
select public.join_ride(tests.ride_id('Petite sortie'));
select tests.authenticate_as('carol');
select tests.throws(format('select public.join_ride(%L)', tests.ride_id('Petite sortie')),
  'ride_full', 'capacité atteinte : adhésion refusée');

-- -----------------------------------------------------------------------------
-- Départs et retraits
-- -----------------------------------------------------------------------------
select tests.authenticate_as('alice');
select tests.throws(format('select public.leave_ride(%L)', tests.ride_id('Petite sortie')),
  'organizer_cannot_leave', 'l''organisateur ne quitte pas sa balade');
select tests.throws(
  format('select public.remove_ride_participant(%L, %L)', tests.ride_id('Petite sortie'), tests.uid('alice')),
  'not_allowed', 'l''organisateur ne peut pas être retiré');

select tests.authenticate_as('bob');
select public.leave_ride(tests.ride_id('Petite sortie'));
select tests.ok(
  (select participant_count = 1 from public.rides where title = 'Petite sortie'),
  'départ volontaire : compteur mis à jour');
select tests.authenticate_as('carol');
select tests.ok(public.join_ride(tests.ride_id('Petite sortie')) = 'joined',
  'une place libérée peut être reprise');

-- Retrait d'un participant d'une balade privée : perte d'accès immédiate.
select tests.authenticate_as('dave');
select tests.ok(
  tests.count_of(format('select 1 from public.ride_participants where ride_id = %L and status = %L',
                        tests.ride_id('Sortie privée'), 'confirmed')) = 2,
  'un participant confirmé voit la liste des participants');
select tests.ok(private.is_ride_participant(tests.ride_id('Sortie privée')),
  'accès aux données réservées aux participants');
select tests.authenticate_as('alice');
select public.remove_ride_participant(tests.ride_id('Sortie privée'), tests.uid('dave'));
select tests.authenticate_as('dave');
select tests.ok(not private.is_ride_participant(tests.ride_id('Sortie privée')),
  'retiré : plus d''accès aux données réservées aux participants');
select tests.ok(tests.count_of($$select 1 from public.rides where title = 'Sortie privée'$$) = 0,
  'retiré : la balade privée redevient invisible');
select tests.ok(
  tests.count_of(format('select 1 from public.ride_participants where ride_id = %L and user_id <> %L',
                        tests.ride_id('Sortie privée'), tests.uid('dave'))) = 0,
  'retiré : la liste des participants est inaccessible');
select tests.throws(format('select public.join_ride(%L)', tests.ride_id('Sortie privée')),
  'ride_not_found', 'retiré : impossible de revenir sur une balade privée');

-- Balade publique : retiré = ne peut pas revenir de lui-même.
select tests.authenticate_as('alice');
select public.remove_ride_participant(tests.ride_id('Tour du fleuve'), tests.uid('bob'));
select tests.authenticate_as('bob');
select tests.throws(format('select public.join_ride(%L)', tests.ride_id('Tour du fleuve')),
  'removed_from_ride', 'retiré d''une balade publique : pas de retour par soi-même');

-- -----------------------------------------------------------------------------
-- Balades de club
-- -----------------------------------------------------------------------------
select tests.authenticate_as('alice');
select public.create_ride('Sortie du club', now() + interval '1 day', 'Kinshasa', 'Siège du club', 'Kasangulu',
                          'club', 'open', p_club_id => tests.club_id('Kin Riders'), p_publish => true);
select public.create_ride('Sortie du club ouverte', now() + interval '1 day', 'Kinshasa', 'Siège', 'Kisantu',
                          'club', 'open', p_club_id => tests.club_id('Kin Riders'),
                          p_open_to_non_members => true, p_publish => true);

select tests.authenticate_as('bob');
select tests.ok(public.join_ride(tests.ride_id('Sortie du club')) = 'joined',
  'un membre du club rejoint la balade réservée aux membres');

select tests.authenticate_as('eve');
select tests.ok(tests.count_of($$select 1 from public.rides where title = 'Sortie du club'$$) = 0,
  'balade réservée aux membres : invisible pour les non-membres');
select tests.throws(format('select public.join_ride(%L)', tests.ride_id('Sortie du club')),
  'ride_not_found', 'balade réservée aux membres : non-membre refusé');
select tests.ok(public.join_ride(tests.ride_id('Sortie du club ouverte')) = 'joined',
  'balade de club ouverte : un non-membre peut rejoindre');

select tests.authenticate_as('alice');
select tests.throws(
  format('select public.invite_to_ride(%L, %L)', tests.ride_id('Sortie du club'), tests.uid('eve')),
  'club_members_only', 'une invitation ne contourne pas la restriction aux membres du club');

-- Un administrateur du club gère les balades du club.
select public.set_club_member_role(tests.club_id('Kin Riders'), tests.uid('bob'), 'admin');
select tests.authenticate_as('bob');
select public.set_ride_status(tests.ride_id('Sortie du club'), 'lock');
select tests.ok(tests.ride_state('Sortie du club') = 'locked+locked',
  'un administrateur du club gère la balade du club');

-- -----------------------------------------------------------------------------
-- Confidentialité
-- -----------------------------------------------------------------------------
select tests.authenticate_as('mallory');
insert into public.profile_settings (user_id, discoverable, allow_ride_invitations)
values (tests.uid('mallory'), false, false);
select tests.authenticate_as('alice');
select tests.throws(
  format('select public.invite_to_ride(%L, %L)', tests.ride_id('Petite sortie'), tests.uid('mallory')),
  'invitations_disabled', 'invitations de balade refusées par la préférence de l''utilisateur');

select tests.authenticate_as('carol');
insert into public.profile_settings (user_id, discoverable) values (tests.uid('carol'), false);
select tests.authenticate_as('alice');
select tests.ok(tests.count_of(format('select 1 from public.profiles where id = %L', tests.uid('carol'))) = 1,
  'profil non découvrable : visible des participants d''une même balade');
select tests.authenticate_as('zoe');
select tests.ok(tests.count_of(format('select 1 from public.profiles where id = %L', tests.uid('carol'))) = 0,
  'profil non découvrable : invisible sans relation');

-- -----------------------------------------------------------------------------
-- Recherche de proximité (PostGIS)
-- -----------------------------------------------------------------------------
select tests.authenticate_as('zoe');
select tests.ok(
  (select array_agg(title order by title) from public.rides_near(-4.32, 15.31, 10))
    = array['Tour du fleuve'],
  'balades proches de Kinshasa : Lubumbashi exclue, balade privée invisible exclue');
select tests.ok(
  (select count(*) from public.rides_near(-4.32, 15.31, 500)) = 1,
  '500 km autour de Kinshasa n''atteignent pas Lubumbashi (≈ 1 600 km)');
select tests.ok(
  (select title from public.rides_near(-11.66, 27.48, 25)) = 'Lubumbashi – Likasi',
  'balades proches de Lubumbashi');
select tests.throws($$select * from public.rides_near(-4.32, 15.31, 5000)$$,
  'invalid_input', 'rayon de recherche limité');

-- -----------------------------------------------------------------------------
-- Visiteur anonyme et journal
-- -----------------------------------------------------------------------------
select tests.authenticate_as_anon();
select tests.throws($$select * from public.rides$$, 'permission denied',
  'un visiteur anonyme ne lit pas les balades');
select tests.throws(
  $$select public.create_ride('Anonyme', now() + interval '1 day', 'Kinshasa', 'A1', 'B1', 'public', 'open')$$,
  'permission denied', 'un visiteur anonyme ne crée pas de balade');
select tests.throws($$select * from public.rides_near(-4.32, 15.31, 10)$$, 'permission denied',
  'un visiteur anonyme n''utilise pas la recherche de proximité');

reset role;
select tests.ok(
  (select count(*) >= 20 from private.audit_logs where action like 'ride.%')
  and exists (select 1 from private.audit_logs where action = 'ride.participant.remove'),
  'les opérations sur les balades sont journalisées');

rollback;
