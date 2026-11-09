-- =============================================================================
-- Profils : création automatique, lecture, modification par le propriétaire.
-- =============================================================================
begin;

select tests.create_user('alice');
select tests.create_user('bob');
-- Pseudonyme déjà pris + nom vide : valeurs de repli, l'inscription aboutit.
select tests.create_user('alice2', '{"username": "alice", "display_name": ""}');
-- Pseudonyme invalide.
select tests.create_user('weird', '{"username": "Pas Valide!", "display_name": "Weird"}');

select tests.ok(
  (select username = 'alice' and display_name = 'Alice'
     from public.profiles where id = tests.uid('alice')),
  'profil créé automatiquement à l''inscription');
select tests.ok(
  (select username like 'rider\_%' and display_name = 'Motard'
     from public.profiles where id = tests.uid('alice2')),
  'pseudonyme déjà pris : valeur de repli, compte créé');
select tests.ok(
  (select username like 'rider\_%' from public.profiles where id = tests.uid('weird')),
  'pseudonyme invalide : valeur de repli');

-- Acceptation 1 (partie base) : un compte = un profil.
select tests.ok(
  (select count(*) = 1 from public.profiles where id = tests.uid('alice')),
  'un seul profil par compte');

select tests.authenticate_as('bob');
select tests.ok(tests.count_of('select 1 from public.profiles') = 4,
  'un utilisateur connecté voit les profils publics');
select tests.ok(
  tests.rows_affected($$update public.profiles set display_name = 'Piraté'
                         where username = 'alice'$$) = 0,
  'bob ne peut pas modifier le profil d''alice');
select tests.ok(
  tests.rows_affected($$update public.profiles set display_name = 'Bob le motard', city = 'Kinshasa'
                         where id = tests.uid('bob')$$) = 1,
  'bob modifie son propre profil');
select tests.throws(
  $$update public.profiles set created_at = now() - interval '1 year' where id = tests.uid('bob')$$,
  'permission denied', 'les colonnes techniques ne sont pas modifiables');
select tests.throws(
  $$update public.profiles set username = 'alice' where id = tests.uid('bob')$$,
  'duplicate key', 'pseudonyme unique');
select tests.throws(
  $$update public.profiles set username = 'Bob Majuscule' where id = tests.uid('bob')$$,
  'profiles_username_format', 'format de pseudonyme vérifié');
select tests.throws(
  $$insert into public.profiles (id, username, display_name) values (gen_random_uuid(), 'fake', 'Fake')$$,
  'permission denied', 'aucune création directe de profil');
select tests.throws(
  $$delete from public.profiles where id = tests.uid('bob')$$,
  'permission denied', 'aucune suppression directe de profil');

select tests.authenticate_as_anon();
select tests.throws($$select * from public.profiles$$, 'permission denied',
  'un visiteur anonyme ne lit pas les profils');

reset role;
rollback;
