-- =============================================================================
-- Regroupements de motards et vérification des motards (sans paiement).
-- =============================================================================
begin;

select tests.create_user(u) from unnest(array['motard', 'autre', 'equipe']) u;
select tests.verify_rider(u) from unnest(array['motard']) u;
insert into private.platform_admins (user_id) values (tests.uid('equipe'));

-- Regroupement : un club de type 'regroupement', type non modifiable.
select tests.authenticate_as('motard');
select public.create_regroupement('Motards de Gombe', 'Kinshasa', 'public', 'open');
select tests.ok((select kind = 'regroupement' from public.clubs where name = 'Motards de Gombe'),
  'regroupement créé avec son type');
select public.create_club('Club Simple', 'Kinshasa', 'public', 'open');
select tests.ok((select kind = 'club' from public.clubs where name = 'Club Simple'),
  'un club reste un club');
select tests.throws(
  format($$update public.clubs set kind = 'club' where id = %L$$, tests.club_id('Motards de Gombe')),
  'permission denied', 'le type ne se modifie pas');
select tests.ok(public.request_club_verification(tests.club_id('Motards de Gombe'), 'Motards de Gombe',
  'Jean', '+243810000000') is not null, 'un regroupement peut demander la vérification');

-- Vérification d'un motard (repart d'un profil non vérifié).
reset role;
update public.profiles set verified_at = null, verified_until = null where id = tests.uid('motard');
select tests.authenticate_as('motard');
select tests.throws(
  $$update public.profiles set verified_at = now() where id = auth.uid()$$,
  'permission denied', 'on ne se vérifie pas soi-même');
insert into storage.objects (bucket_id, name)
values ('verification-docs', 'riders/' || tests.uid('motard') || '/carte.jpg');
select tests.authenticate_as('autre');
select tests.throws(
  format($$insert into storage.objects (bucket_id, name) values ('verification-docs', %L)$$,
         'riders/' || tests.uid('motard') || '/faux.jpg'),
  'row-level security', 'pas de dépôt dans le dossier d''un autre');
select tests.ok(tests.count_of($$select 1 from storage.objects where bucket_id = 'verification-docs'$$) = 0,
  'les pièces d''un autre motard sont invisibles');
select tests.authenticate_as('motard');
select tests.throws($$select public.request_rider_verification('Jean Mukendi', 'abc')$$,
  'invalid_input', 'numéro invalide refusé');
select tests.throws(
  format($$select public.request_rider_verification('Jean', '+243810000000', null, array[%L])$$,
         'riders/' || tests.uid('autre') || '/x.jpg'),
  'invalid_input', 'pièce d''un autre refusée');
select public.request_rider_verification('Jean Mukendi', '+243 81 000 0000', 'Motard depuis 2015',
  array['riders/' || tests.uid('motard') || '/carte.jpg']);
select tests.throws($$select public.request_rider_verification('Jean Mukendi', '+243810000000')$$,
  'verification_pending', 'une seule demande en cours');
select tests.throws('select * from public.rider_verification_queue()', 'not_allowed',
  'file réservée à l''équipe');
select tests.authenticate_as('autre');
select tests.ok(tests.count_of('select 1 from public.rider_verification_requests') = 0,
  'les demandes des autres sont privées');

select tests.authenticate_as('equipe');
select tests.ok((select real_name = 'Jean Mukendi' and contact_phone = '+243810000000'
                   from public.rider_verification_queue()), 'l''équipe voit la demande');
select public.review_rider_verification(
  (select request_id from public.rider_verification_queue()), true);
select tests.ok((select verified_at is not null and verified_until > now() + interval '360 days'
                   from public.profiles where id = tests.uid('motard')), 'motard vérifié pour un an');
select tests.authenticate_as('motard');
select tests.ok(exists (select 1 from public.notifications
                         where user_id = tests.uid('motard') and kind = 'rider_verification_approved'),
  'le motard est prévenu');
select tests.throws($$select public.request_rider_verification('Jean Mukendi', '+243810000000')$$,
  'already_verified', 'déjà vérifié');

-- Rappel puis expiration.
reset role;
update public.profiles set verified_until = now() + interval '5 days' where id = tests.uid('motard');
select private.process_rider_verifications();
select tests.ok(exists (select 1 from public.notifications
                         where user_id = tests.uid('motard') and kind = 'rider_verification_expiring'),
  'rappel avant la fin');
update public.profiles set verified_until = now() - interval '1 minute' where id = tests.uid('motard');
select private.process_rider_verifications();
select tests.ok((select verified_at is null from public.profiles where id = tests.uid('motard')),
  'badge retiré à l''échéance');

-- Retrait par l'équipe.
update public.profiles set verified_at = now(), verified_until = now() + interval '1 year'
 where id = tests.uid('autre');
select tests.authenticate_as('autre');
select tests.throws(format($$select public.revoke_rider_verification(%L)$$, tests.uid('motard')),
  'not_allowed', 'seule l''équipe retire un badge');
select tests.authenticate_as('equipe');
select public.revoke_rider_verification(tests.uid('autre'), 'Faux nom');
select tests.ok((select verified_at is null from public.profiles where id = tests.uid('autre')),
  'badge retiré par l''équipe');

rollback;
