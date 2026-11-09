-- =============================================================================
-- Clubs : création libre, visibilité, adhésion, rôles, vérification.
-- Couvre les critères d'acceptation 2, 3, 4, 5 et 15 du cahier des charges.
-- =============================================================================
begin;

select tests.create_user(u) from unnest(array['alice', 'bob', 'carol', 'dave', 'eve', 'mallory']) u;
-- eve est administratrice de la plateforme Rider Group.
insert into private.platform_admins (user_id) values (tests.uid('eve'));

-- -----------------------------------------------------------------------------
-- Acceptation 3 : création libre, sans approbation préalable.
-- -----------------------------------------------------------------------------
select tests.authenticate_as('alice');
select public.create_club('Kin Riders', 'Kinshasa', 'public', 'open',
                          p_description => 'Balades autour de Kinshasa');
select tests.ok(
  (select member_count = 1 and owner_id = tests.uid('alice') and verified_at is null
     from public.clubs where name = 'Kin Riders'),
  'club public créé sans approbation, compteur = 1, non vérifié');
select tests.ok(
  (select role = 'owner' from public.club_members
    where club_id = tests.club_id('Kin Riders') and user_id = tests.uid('alice')),
  'le créateur devient propriétaire');

-- Club privé masqué, sur invitation uniquement.
select public.create_club('Secret MC', 'Kinshasa', 'private', 'invite_only', p_is_listed => false,
                          p_rules => 'Règlement réservé aux membres');

-- Validation des entrées.
select tests.throws($$select public.create_club('Kin Riders', 'Kinshasa', 'public', 'open')$$,
  'club_name_taken', 'nom de club unique');
select tests.throws($$select public.create_club('KIN RIDERS ', 'Kinshasa', 'public', 'open')$$,
  'club_name_taken', 'unicité insensible à la casse et aux espaces');
select tests.throws($$select public.create_club('Ab', 'Kinshasa', 'public', 'open')$$,
  'invalid_input', 'nom trop court refusé');
select tests.throws($$select public.create_club('Mauvais réglage', 'Kinshasa', 'public', 'invite_only')$$,
  'invalid_input', 'club public sur invitation refusé');
select tests.throws($$select public.create_club('Privé ouvert', 'Kinshasa', 'private', 'open')$$,
  'invalid_input', 'club privé à adhésion libre refusé');

-- -----------------------------------------------------------------------------
-- Club privé référencé, sur approbation (dave).
-- -----------------------------------------------------------------------------
select tests.authenticate_as('dave');
select public.create_club('Lions Lubumbashi', 'Lubumbashi', 'private', 'approval', p_is_listed => true);

-- -----------------------------------------------------------------------------
-- Acceptation 5 : contenus privés protégés.
-- -----------------------------------------------------------------------------
select tests.authenticate_as('bob');
select tests.ok(tests.count_of($$select 1 from public.clubs where name = 'Secret MC'$$) = 0,
  'un club privé masqué est invisible pour un non-membre');
select tests.ok(tests.count_of($$select 1 from public.clubs where name = 'Lions Lubumbashi'$$) = 1,
  'un club privé référencé est visible (vitrine)');
select tests.ok(
  tests.count_of(format('select 1 from public.club_members where club_id = %L',
                        tests.club_id('Lions Lubumbashi'))) = 0,
  'la liste des membres d''un club privé est cachée aux non-membres');
select tests.ok(
  tests.count_of(format('select 1 from public.club_members where club_id = %L',
                        tests.club_id('Secret MC'))) = 0,
  'la liste des membres d''un club masqué est cachée');
select tests.throws(format('select public.join_club(%L)', tests.club_id('Secret MC')),
  'club_not_found', 'impossible de rejoindre un club masqué par son identifiant');

-- -----------------------------------------------------------------------------
-- Acceptation 2 : un motard appartient à plusieurs clubs.
-- -----------------------------------------------------------------------------
select tests.ok(public.join_club(tests.club_id('Kin Riders')) = 'joined',
  'adhésion libre : bob rejoint Kin Riders immédiatement');
select tests.throws(format('select public.join_club(%L)', tests.club_id('Kin Riders')),
  'already_member', 'pas de double adhésion');
select tests.ok(public.join_club(tests.club_id('Lions Lubumbashi'), 'Je roule en Bajaj') = 'requested',
  'adhésion sur approbation : demande créée');
select tests.ok(public.join_club(tests.club_id('Lions Lubumbashi')) = 'requested',
  'une seconde demande est idempotente');
select tests.ok(
  tests.count_of($$select 1 from public.club_join_requests where status = 'pending'$$) = 1,
  'bob voit sa propre demande (une seule en attente)');

select tests.authenticate_as('carol');
select tests.ok(tests.count_of('select 1 from public.club_join_requests') = 0,
  'un tiers ne voit pas les demandes d''adhésion');
select tests.throws(
  format('select public.decide_club_join_request(%L, true)',
         tests.join_request_id('Lions Lubumbashi', 'bob')),
  'not_allowed', 'un non-administrateur ne peut pas approuver');

select tests.authenticate_as('dave');
select public.decide_club_join_request(tests.join_request_id('Lions Lubumbashi', 'bob'), true);

select tests.authenticate_as('bob');
select tests.ok(
  (select count(*) = 2 from public.club_members where user_id = tests.uid('bob')),
  'bob est membre de deux clubs');
select tests.ok(
  tests.count_of(format('select 1 from public.club_members where club_id = %L',
                        tests.club_id('Lions Lubumbashi'))) = 2,
  'devenu membre, bob voit la liste des membres du club privé');

-- -----------------------------------------------------------------------------
-- Invitations (club privé masqué).
-- -----------------------------------------------------------------------------
select tests.authenticate_as('carol');
select tests.throws(format('select public.invite_to_club(%L, %L)',
                           tests.club_id('Kin Riders'), tests.uid('mallory')),
  'not_allowed', 'un non-membre ne peut pas inviter');

select tests.authenticate_as('alice');
select public.invite_to_club(tests.club_id('Secret MC'), tests.uid('carol'));
select tests.ok(
  public.invite_to_club(tests.club_id('Secret MC'), tests.uid('carol'))
    = (select id from public.club_invitations where invitee_id = tests.uid('carol')),
  'une invitation en double renvoie l''invitation existante');
select tests.throws(format('select public.invite_to_club(%L, %L)',
                           tests.club_id('Secret MC'), tests.uid('alice')),
  'already_member', 'impossible d''inviter un membre');

select tests.authenticate_as('carol');
select tests.ok(tests.count_of($$select 1 from public.clubs where name = 'Secret MC'$$) = 1,
  'une personne invitée voit le club masqué');
select tests.ok(
  tests.count_of(format('select 1 from public.club_members where club_id = %L',
                        tests.club_id('Secret MC'))) = 0,
  'une personne invitée ne voit pas encore les membres');
select public.respond_to_club_invitation(
  (select id from public.club_invitations where invitee_id = tests.uid('carol')), true);
select tests.ok(
  tests.count_of(format('select 1 from public.club_members where club_id = %L',
                        tests.club_id('Secret MC'))) = 2,
  'invitation acceptée : carol est membre et voit les membres');

select tests.authenticate_as('bob');
select tests.throws(format('select public.join_club(%L)', tests.club_id('Secret MC')),
  'club_not_found', 'sans invitation, le club masqué reste inaccessible');

-- Invitation-only référencé : la demande directe est refusée.
select tests.authenticate_as('alice');
update public.clubs set is_listed = true where name = 'Secret MC';
select tests.authenticate_as('bob');
select tests.throws(format('select public.join_club(%L)', tests.club_id('Secret MC')),
  'invitation_required', 'club sur invitation : adhésion directe refusée');
select tests.authenticate_as('alice');
update public.clubs set is_listed = false where name = 'Secret MC';

-- -----------------------------------------------------------------------------
-- Acceptation 15 : permissions par rôle, vérifiées côté serveur.
-- -----------------------------------------------------------------------------
select tests.authenticate_as('carol');
select public.join_club(tests.club_id('Kin Riders'));

select tests.authenticate_as('bob');
select tests.ok(
  tests.rows_affected($$update public.clubs set description = 'Piraté' where name = 'Kin Riders'$$) = 0,
  'un simple membre ne modifie pas le club');
select tests.throws(
  format('select public.set_club_member_role(%L, %L, %L)',
         tests.club_id('Kin Riders'), tests.uid('bob'), 'admin'),
  'not_allowed', 'un membre ne peut pas se promouvoir');
select tests.throws(
  format('select public.remove_club_member(%L, %L)', tests.club_id('Kin Riders'), tests.uid('carol')),
  'not_allowed', 'un membre ne peut pas retirer un autre membre');
select tests.throws(
  $$insert into public.club_members (club_id, user_id, role)
    values (tests.club_id('Secret MC'), tests.uid('bob'), 'owner')$$,
  'permission denied', 'aucune insertion directe dans club_members');
select tests.throws(
  $$update public.club_members set role = 'owner' where user_id = tests.uid('bob')$$,
  'permission denied', 'aucune modification directe des rôles');

select tests.authenticate_as('alice');
select public.set_club_member_role(tests.club_id('Kin Riders'), tests.uid('bob'), 'admin');
select tests.throws(
  format('select public.set_club_member_role(%L, %L, %L)',
         tests.club_id('Kin Riders'), tests.uid('bob'), 'owner'),
  'use_transfer_ownership', 'la propriété ne s''attribue pas comme un rôle');

select tests.authenticate_as('bob');
select tests.ok(
  tests.rows_affected($$update public.clubs set description = 'Nouvelle description'
                         where name = 'Kin Riders'$$) = 1,
  'un administrateur modifie la description');
select tests.throws(
  $$update public.clubs set join_policy = 'approval' where name = 'Kin Riders'$$,
  'not_allowed', 'un administrateur ne change pas le mode d''adhésion (propriétaire seul)');
select tests.throws(
  format('select public.set_club_member_role(%L, %L, %L)',
         tests.club_id('Kin Riders'), tests.uid('alice'), 'member'),
  'not_allowed', 'un administrateur ne rétrograde pas le propriétaire');
select public.set_club_member_role(tests.club_id('Kin Riders'), tests.uid('carol'), 'moderator');
select tests.throws(
  format('select public.set_club_member_role(%L, %L, %L)',
         tests.club_id('Kin Riders'), tests.uid('carol'), 'admin'),
  'not_allowed', 'un administrateur ne crée pas d''autre administrateur');
select tests.throws(
  format('select public.remove_club_member(%L, %L)', tests.club_id('Kin Riders'), tests.uid('alice')),
  'not_allowed', 'un administrateur ne retire pas le propriétaire');

select tests.authenticate_as('carol');
select tests.throws(
  format('select public.remove_club_member(%L, %L)', tests.club_id('Kin Riders'), tests.uid('bob')),
  'not_allowed', 'un modérateur ne retire pas un administrateur');

select tests.authenticate_as('bob');
select public.remove_club_member(tests.club_id('Kin Riders'), tests.uid('carol'));
select tests.ok(
  (select member_count = 2 from public.clubs where name = 'Kin Riders'),
  'un administrateur retire un modérateur ; compteur mis à jour');

select tests.authenticate_as('alice');
select tests.throws(format('select public.leave_club(%L)', tests.club_id('Kin Riders')),
  'owner_cannot_leave', 'le propriétaire ne quitte pas sans transfert');
select tests.ok(
  tests.rows_affected($$update public.clubs set join_policy = 'approval' where name = 'Kin Riders'$$) = 1,
  'le propriétaire change le mode d''adhésion');
select public.transfer_club_ownership(tests.club_id('Kin Riders'), tests.uid('bob'));
select tests.ok(
  (select owner_id = tests.uid('bob') from public.clubs where name = 'Kin Riders')
  and private.club_role_of(tests.club_id('Kin Riders'), tests.uid('alice')) = 'admin'
  and private.club_role_of(tests.club_id('Kin Riders'), tests.uid('bob')) = 'owner',
  'transfert de propriété : bob propriétaire, alice administratrice');
select public.leave_club(tests.club_id('Kin Riders'));
select tests.ok(
  private.club_role_of(tests.club_id('Kin Riders'), tests.uid('alice')) is null,
  'l''ancienne propriétaire peut quitter le club');

-- -----------------------------------------------------------------------------
-- Acceptation 4 : un club ne peut pas s'attribuer le badge vérifié.
-- -----------------------------------------------------------------------------
select tests.authenticate_as('dave');
select tests.throws(
  $$update public.clubs set verified_at = now() where name = 'Lions Lubumbashi'$$,
  'permission denied', 'le propriétaire ne peut pas écrire verified_at');
select tests.throws(
  $$update public.clubs set member_count = 9999 where name = 'Lions Lubumbashi'$$,
  'permission denied', 'le compteur de membres n''est pas modifiable');
select tests.throws(
  $$update public.clubs set owner_id = tests.uid('mallory') where name = 'Lions Lubumbashi'$$,
  'permission denied', 'owner_id n''est pas modifiable directement');

select tests.authenticate_as('bob');
select tests.throws(
  format('select public.request_club_verification(%L)', tests.club_id('Lions Lubumbashi')),
  'not_allowed', 'seul le propriétaire demande la vérification');

select tests.authenticate_as('dave');
select public.request_club_verification(tests.club_id('Lions Lubumbashi'), 'Club fondé en 2015');
select tests.throws(
  format('select public.request_club_verification(%L)', tests.club_id('Lions Lubumbashi')),
  'verification_pending', 'une seule demande en attente');
select tests.throws(
  format('select public.review_club_verification(%L, true)',
         (select id from public.club_verification_requests limit 1)),
  'not_allowed', 'le propriétaire ne peut pas approuver sa propre demande');

select tests.authenticate_as('bob');
select tests.ok(
  tests.count_of(format('select 1 from public.club_verification_requests where club_id = %L',
                        tests.club_id('Lions Lubumbashi'))) = 0,
  'un simple membre ne voit pas les demandes de vérification');

select tests.authenticate_as('eve');
select tests.ok(tests.count_of('select 1 from public.club_verification_requests') = 1,
  'l''administration voit les demandes de vérification');
select public.review_club_verification(
  (select id from public.club_verification_requests limit 1), true, 'Documents vérifiés');
select tests.ok(
  (select verified_at is not null from public.clubs where name = 'Lions Lubumbashi'),
  'badge accordé après validation par l''administration');
select tests.ok(
  tests.count_of(format('select 1 from public.club_members where club_id = %L',
                        tests.club_id('Secret MC'))) = 0,
  'l''administration n''obtient aucun accès aux membres d''un club privé');

select tests.authenticate_as('dave');
select tests.throws(
  format('select public.request_club_verification(%L)', tests.club_id('Lions Lubumbashi')),
  'already_verified', 'pas de nouvelle demande pour un club déjà vérifié');

-- -----------------------------------------------------------------------------
-- Abus, anonymes, suppression, audit.
-- -----------------------------------------------------------------------------
select tests.authenticate_as('mallory');
select public.create_club('Spam 1', 'Goma', 'public', 'open');
select public.create_club('Spam 2', 'Goma', 'public', 'open');
select public.create_club('Spam 3', 'Goma', 'public', 'open');
select tests.throws($$select public.create_club('Spam 4', 'Goma', 'public', 'open')$$,
  'rate_limited', 'limitation : 3 créations de club par 24 h');
select tests.throws(format('select public.delete_club(%L)', tests.club_id('Lions Lubumbashi')),
  'not_allowed', 'seul le propriétaire supprime un club');
select public.delete_club(tests.club_id('Spam 1'));
select tests.ok(tests.club_id('Spam 1') is null, 'le propriétaire supprime son club');

select tests.authenticate_as_anon();
select tests.throws($$select * from public.clubs$$, 'permission denied',
  'un visiteur anonyme ne lit pas les clubs');
select tests.throws($$select public.create_club('Anonyme', 'Goma', 'public', 'open')$$,
  'permission denied', 'un visiteur anonyme ne crée pas de club');

select tests.authenticate_as('alice');
select tests.throws($$select * from private.audit_logs$$, 'permission denied',
  'le journal d''audit est inaccessible aux clients');
select tests.throws($$select * from private.platform_admins$$, 'permission denied',
  'la liste des administrateurs est inaccessible aux clients');

reset role;
select tests.ok(
  (select count(*) >= 15 from private.audit_logs)
  and exists (select 1 from private.audit_logs where action = 'club.verification.approve'
                                               and actor_id = tests.uid('eve')),
  'les opérations sensibles sont journalisées avec leur auteur');

rollback;
