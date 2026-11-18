-- =============================================================================
-- Suppression encadrée des clubs vérifiés (15 jours, examen par l'équipe).
-- =============================================================================
begin;

select tests.create_user(u) from unnest(array['patron', 'adjoint', 'membre', 'equipe']) u;
select tests.verify_rider(u) from unnest(array['patron']) u;
insert into private.platform_admins (user_id) values (tests.uid('equipe'));

select tests.authenticate_as('patron');
select public.create_club('Phoenix Riders', 'Kinshasa', 'public', 'open');
select public.create_club('Petit Club', 'Kinshasa', 'public', 'open');
select tests.authenticate_as('adjoint');
select public.join_club(tests.club_id('Phoenix Riders'));
select tests.authenticate_as('membre');
select public.join_club(tests.club_id('Phoenix Riders'));
select tests.authenticate_as('patron');
select public.set_club_member_role(tests.club_id('Phoenix Riders'), tests.uid('adjoint'), 'admin');

-- Club non vérifié : suppression directe comme avant.
select public.delete_club(tests.club_id('Petit Club'));
select tests.ok(tests.club_id('Petit Club') is null, 'club non vérifié supprimé directement');

reset role;
update public.clubs set verified_at = now(), verified_until = now() + interval '1 year'
 where name = 'Phoenix Riders';

select tests.authenticate_as('patron');
select tests.throws(format($$select public.delete_club(%L)$$, tests.club_id('Phoenix Riders')),
  'deletion_review_required', 'club vérifié : suppression directe refusée');
select tests.throws(format($$select public.request_club_deletion(%L, 'court')$$, tests.club_id('Phoenix Riders')),
  'invalid_input', 'une raison est obligatoire');
select tests.authenticate_as('adjoint');
select tests.throws(format($$select public.request_club_deletion(%L, 'Je veux supprimer ce club')$$,
         tests.club_id('Phoenix Riders')),
  'not_allowed', 'seul le propriétaire demande la suppression');

select tests.authenticate_as('patron');
select public.request_club_deletion(tests.club_id('Phoenix Riders'), 'Le club arrête ses activités en 2027');
select tests.throws(format($$select public.request_club_deletion(%L, 'Encore une demande ici')$$,
         tests.club_id('Phoenix Riders')),
  'deletion_pending', 'une seule demande en cours');

select tests.authenticate_as('adjoint');
select tests.ok((select data->>'reason' = 'Le club arrête ses activités en 2027'
                   from public.notifications where kind = 'club_deletion_requested'),
  'les autres responsables voient la raison');
select tests.authenticate_as('membre');
select tests.ok(tests.count_of('select 1 from public.club_deletion_requests') = 0,
  'un simple membre ne voit pas la demande');
select tests.throws('select * from public.club_deletion_queue()', 'not_allowed', 'file réservée à l''équipe');

select tests.authenticate_as('equipe');
select tests.ok((select reason = 'Le club arrête ses activités en 2027' and member_count = 3
                   from public.club_deletion_queue()), 'l''équipe voit la raison et le club');
select tests.ok(exists (select 1 from public.notifications where kind = 'club_deletion_requested'),
  'l''équipe est prévenue');

-- Refus : le club reste.
select public.review_club_deletion((select request_id from public.club_deletion_queue()), false, 'Litige entre membres');
select tests.ok(tests.club_id('Phoenix Riders') is not null, 'refus : le club est conservé');

-- Annulation par le propriétaire.
select tests.authenticate_as('patron');
select public.request_club_deletion(tests.club_id('Phoenix Riders'), 'Deuxième demande de fermeture');
select public.cancel_club_deletion(tests.club_id('Phoenix Riders'));
select tests.ok(not exists (select 1 from public.club_deletion_requests where status = 'pending'),
  'demande annulée');

-- Sans décision après 15 jours : suppression automatique.
select public.request_club_deletion(tests.club_id('Phoenix Riders'), 'Troisième demande de fermeture');
reset role;
select tests.ok(private.process_club_deletions() = 0, 'rien avant 15 jours');
update public.club_deletion_requests set due_at = now() - interval '1 minute' where status = 'pending';
select tests.ok(private.process_club_deletions() = 1, 'traitement après 15 jours');
select tests.ok(tests.club_id('Phoenix Riders') is null, 'club supprimé automatiquement');
select tests.ok(exists (select 1 from public.notifications
                         where kind = 'club_deletion_auto' and user_id = tests.uid('patron')),
  'le propriétaire est prévenu');

rollback;
