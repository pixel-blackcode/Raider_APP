-- =============================================================================
-- Vérification des clubs sans paiement : demande, examen, expiration, retrait.
-- =============================================================================
begin;

select tests.create_user(u) from unnest(array['patron', 'adjoint', 'membre', 'equipe']) u;
insert into private.platform_admins (user_id) values (tests.uid('equipe'));

select tests.authenticate_as('patron');
select public.create_club('Phoenix Riders', 'Kinshasa', 'public', 'open');
select tests.authenticate_as('adjoint');
select public.join_club(tests.club_id('Phoenix Riders'));
select tests.authenticate_as('membre');
select public.join_club(tests.club_id('Phoenix Riders'));
select tests.authenticate_as('patron');
select public.set_club_member_role(tests.club_id('Phoenix Riders'), tests.uid('adjoint'), 'admin');

-- Aucune trace de paiement dans le schéma (règles Apple / Google).
select tests.ok(not exists (
  select 1 from information_schema.columns
   where table_schema = 'public'
     and (column_name ilike '%price%' and table_name like 'club%'
          or column_name ilike '%payment%' or column_name ilike '%amount%')),
  'aucune colonne de prix, montant ou paiement pour la vérification');

-- Demande par un administrateur du club, avec document privé.
select tests.authenticate_as('membre');
select tests.throws(
  format($$select public.request_club_verification(%L, 'Phoenix', 'Membre', '+243810000000')$$,
         tests.club_id('Phoenix Riders')),
  'not_allowed', 'un simple membre ne demande pas la vérification');
select tests.throws(
  format($$insert into storage.objects (bucket_id, name) values ('verification-docs', %L)$$,
         tests.club_id('Phoenix Riders') || '/statuts.pdf'),
  'row-level security', 'un simple membre ne dépose pas de document');
select tests.authenticate_as('adjoint');
insert into storage.objects (bucket_id, name)
values ('verification-docs', tests.club_id('Phoenix Riders') || '/statuts.pdf');
select tests.throws(
  format($$select public.request_club_verification(%L, 'Phoenix', 'Jean', 'abc')$$,
         tests.club_id('Phoenix Riders')),
  'invalid_input', 'numéro de téléphone invalide refusé');
select public.request_club_verification(tests.club_id('Phoenix Riders'), 'Phoenix Riders ASBL',
  'Jean Mukendi', '+243 81 234 5678', 'Club fondé en 2018',
  array[tests.club_id('Phoenix Riders') || '/statuts.pdf']);
select tests.ok((select contact_phone = '+243812345678' and cardinality(document_paths) = 1
                   from public.club_verification_requests),
  'demande enregistrée, numéro normalisé, document rattaché');
select tests.authenticate_as('membre');
select tests.ok(tests.count_of('select 1 from public.club_verification_requests') = 0,
  'un simple membre ne voit pas la demande (coordonnées privées)');
select tests.ok(tests.count_of($$select 1 from storage.objects where bucket_id = 'verification-docs'$$) = 0,
  'un simple membre ne voit pas les documents');
select tests.throws('select * from public.verification_queue()', 'not_allowed',
  'la file d''examen est réservée à l''équipe');

-- Examen par l'équipe : badge avec date de fin, notification au demandeur.
select tests.authenticate_as('equipe');
select tests.ok(public.am_i_platform_admin(), 'l''équipe est reconnue');
select tests.ok((select official_name = 'Phoenix Riders ASBL' and contact_phone = '+243812345678'
                   from public.verification_queue()),
  'l''équipe voit les coordonnées pour contacter le club hors de l''application');
select tests.ok(tests.count_of($$select 1 from storage.objects where bucket_id = 'verification-docs'$$) = 1,
  'l''équipe voit les documents');
select public.review_club_verification(
  (select request_id from public.verification_queue()), true, 'Documents conformes',
  now() + interval '1 year');
select tests.ok((select verified_at is not null and verified_until > now() + interval '360 days'
                   from public.clubs where name = 'Phoenix Riders'),
  'badge accordé pour un an');
select tests.authenticate_as('adjoint');
select tests.ok(tests.count_of($$select 1 from public.notifications where kind = 'club_verification_approved'$$) = 1,
  'le demandeur est prévenu');
select tests.throws(
  $$update public.clubs set verified_until = now() + interval '10 years' where name = 'Phoenix Riders'$$,
  'permission denied', 'le club ne prolonge pas lui-même son badge');

-- Rappels neutres puis expiration automatique.
reset role;
update public.clubs set verified_until = now() + interval '6 days' where name = 'Phoenix Riders';
select private.process_club_verifications();
select tests.ok((select count(*) = 2 from public.notifications where kind = 'club_verification_expiring'),
  '7 jours avant : rappel au propriétaire et à l''administrateur');
select private.process_club_verifications();
select tests.ok((select count(*) = 2 from public.notifications where kind = 'club_verification_expiring'),
  'pas de rappel en double');
update public.clubs set verified_until = now() + interval '12 hours' where name = 'Phoenix Riders';
select private.process_club_verifications();
select tests.ok((select count(*) = 4 from public.notifications where kind = 'club_verification_expiring'),
  'la veille : second rappel');
update public.clubs set verified_until = now() - interval '1 minute' where name = 'Phoenix Riders';
select private.process_club_verifications();
select tests.ok((select verified_at is null from public.clubs where name = 'Phoenix Riders'),
  'à l''échéance, le badge disparaît');
select tests.ok((select count(*) = 2 from public.notifications where kind = 'club_verification_expired'),
  'le club est prévenu de l''expiration');

-- Renouvellement puis retrait par l'équipe (litige).
select tests.authenticate_as('patron');
select public.request_club_verification(tests.club_id('Phoenix Riders'), 'Phoenix Riders ASBL',
  'Jean Mukendi', '+243812345678');
select tests.authenticate_as('equipe');
select public.review_club_verification((select request_id from public.verification_queue()), true);
select public.revoke_club_verification(tests.club_id('Phoenix Riders'), 'Litige sur le nom');
select tests.ok((select verified_at is null from public.clubs where name = 'Phoenix Riders'),
  'retrait du badge par l''équipe');
reset role;
select tests.ok(exists (select 1 from private.audit_logs where action = 'club.verification.revoke'),
  'retrait journalisé');
select tests.authenticate_as('patron');
select tests.throws(format($$select public.revoke_club_verification(%L)$$, tests.club_id('Phoenix Riders')),
  'not_allowed', 'seule l''équipe retire un badge');

rollback;
