-- =============================================================================
-- Médias (Storage), confidentialité des profils, suppression de compte.
-- =============================================================================
begin;

select tests.create_user(u) from unnest(array['alice', 'bob', 'carol', 'dave', 'mallory']) u;

-- alice : club public « Kin Riders » (bob, carol membres)
-- alice : club privé masqué « Secret MC »
-- mallory : club sans autre membre « Solo » + membre de Kin Riders
select tests.authenticate_as('alice');
select public.create_club('Kin Riders', 'Kinshasa', 'public', 'open');
select public.create_club('Secret MC', 'Kinshasa', 'private', 'invite_only', p_is_listed => false);
select tests.authenticate_as('bob');
select public.join_club(tests.club_id('Kin Riders'));
select tests.authenticate_as('carol');
select public.join_club(tests.club_id('Kin Riders'));
select tests.authenticate_as('mallory');
select public.create_club('Solo', 'Goma', 'public', 'open');
select public.join_club(tests.club_id('Kin Riders'));

-- -----------------------------------------------------------------------------
-- Buckets
-- -----------------------------------------------------------------------------
reset role;
select tests.ok(
  (select count(*) = 2 from storage.buckets
    where id in ('avatars', 'club-media') and not public
      and allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']),
  'buckets privés, limités aux images');

-- -----------------------------------------------------------------------------
-- Photos de profil
-- -----------------------------------------------------------------------------
select tests.authenticate_as('alice');
insert into storage.objects (bucket_id, name)
values ('avatars', tests.uid('alice') || '/avatar-1.jpg');
select tests.ok(true, 'un utilisateur dépose sa photo dans son dossier');
select tests.ok(
  tests.rows_affected(format($$update public.profiles set avatar_path = %L where id = %L$$,
    tests.uid('alice') || '/avatar-1.jpg', tests.uid('alice'))) = 1,
  'le profil référence la photo');
select tests.throws(
  format($$update public.profiles set avatar_path = %L where id = %L$$,
    tests.uid('bob') || '/x.jpg', tests.uid('alice')),
  'profiles_avatar_path_owner', 'un profil ne peut pas pointer vers le dossier d''un autre');

select tests.authenticate_as('bob');
select tests.throws(
  format($$insert into storage.objects (bucket_id, name) values ('avatars', %L)$$,
    tests.uid('alice') || '/pirate.jpg'),
  'row-level security', 'impossible de déposer dans le dossier d''un autre');
select tests.ok(
  tests.rows_affected($$delete from storage.objects where bucket_id = 'avatars'$$) = 0,
  'impossible de supprimer la photo d''un autre');
select tests.ok(
  tests.count_of($$select 1 from storage.objects where bucket_id = 'avatars'$$) = 1,
  'la photo d''un profil visible est lisible');
select tests.throws(
  $$insert into storage.objects (bucket_id, name) values ('avatars', 'avatar-sans-dossier.jpg')$$,
  'row-level security', 'un fichier hors dossier personnel est refusé');

select tests.authenticate_as_anon();
select tests.ok(
  tests.count_of($$select 1 from storage.objects$$) = 0,
  'un visiteur anonyme ne lit aucun média');

-- -----------------------------------------------------------------------------
-- Médias de club
-- -----------------------------------------------------------------------------
select tests.authenticate_as('alice');
insert into storage.objects (bucket_id, name)
values ('club-media', tests.club_id('Secret MC') || '/logo-1.jpg'),
       ('club-media', tests.club_id('Kin Riders') || '/cover-1.jpg');
select tests.ok(true, 'le propriétaire dépose logo et couverture');
select tests.throws(
  format($$update public.clubs set logo_path = %L where id = %L$$,
    tests.club_id('Kin Riders') || '/x.jpg', tests.club_id('Secret MC')),
  'clubs_logo_path_owner', 'un club ne peut pas pointer vers les médias d''un autre club');

select tests.authenticate_as('bob');
select tests.throws(
  format($$insert into storage.objects (bucket_id, name) values ('club-media', %L)$$,
    tests.club_id('Kin Riders') || '/logo-pirate.jpg'),
  'row-level security', 'un simple membre ne dépose pas de média de club');
select tests.ok(
  tests.count_of(format($$select 1 from storage.objects where name like %L$$,
    tests.club_id('Kin Riders') || '/%')) = 1,
  'un membre voit les médias d''un club visible');
select tests.ok(
  tests.count_of(format($$select 1 from storage.objects where name like %L$$,
    tests.club_id('Secret MC') || '/%')) = 0,
  'les médias d''un club masqué sont invisibles aux non-membres');

select tests.authenticate_as('alice');
select public.set_club_member_role(tests.club_id('Kin Riders'), tests.uid('bob'), 'admin');
select tests.authenticate_as('bob');
insert into storage.objects (bucket_id, name)
values ('club-media', tests.club_id('Kin Riders') || '/logo-2.jpg');
select tests.ok(true, 'un administrateur du club dépose un logo');

-- -----------------------------------------------------------------------------
-- Confidentialité
-- -----------------------------------------------------------------------------
select tests.authenticate_as('dave');
select tests.ok(tests.count_of(format('select 1 from public.profiles where id = %L', tests.uid('carol'))) = 1,
  'par défaut, un profil est découvrable');

select tests.authenticate_as('carol');
insert into public.profile_settings (user_id, discoverable, allow_club_invitations)
values (tests.uid('carol'), false, false);
select tests.ok(
  tests.count_of('select 1 from public.profile_settings') = 1,
  'carol lit ses propres préférences');

select tests.authenticate_as('dave');
select tests.ok(tests.count_of(format('select 1 from public.profiles where id = %L', tests.uid('carol'))) = 0,
  'profil non découvrable : invisible hors de ses clubs');
select tests.ok(tests.count_of('select 1 from public.profile_settings') = 0,
  'les préférences d''autrui sont illisibles');
select tests.ok(
  tests.rows_affected(format($$update public.profile_settings set discoverable = true where user_id = %L$$,
    tests.uid('carol'))) = 0,
  'les préférences d''autrui ne sont pas modifiables');
select tests.throws(
  format($$insert into public.profile_settings (user_id, discoverable) values (%L, true)$$, tests.uid('carol')),
  'row-level security', 'impossible de créer les préférences d''autrui');

select tests.authenticate_as('bob');
select tests.ok(tests.count_of(format('select 1 from public.profiles where id = %L', tests.uid('carol'))) = 1,
  'profil non découvrable : visible des membres d''un club commun');

select tests.authenticate_as('alice');
select tests.throws(
  format('select public.invite_to_club(%L, %L)', tests.club_id('Secret MC'), tests.uid('carol')),
  'invitations_disabled', 'invitations désactivées : refus côté serveur');

select tests.authenticate_as('carol');
-- Requête équivalente à l'upsert PostgREST de l'application.
insert into public.profile_settings (user_id, discoverable, allow_club_invitations)
values (tests.uid('carol'), false, true)
on conflict (user_id) do update
  set user_id = excluded.user_id,
      discoverable = excluded.discoverable,
      allow_club_invitations = excluded.allow_club_invitations;
select tests.ok(
  (select allow_club_invitations from public.profile_settings where user_id = tests.uid('carol')),
  'upsert de ses préférences (comme l''application)');
select tests.throws(
  format($$update public.profile_settings set user_id = %L where user_id = %L$$,
    tests.uid('dave'), tests.uid('carol')),
  'row-level security', 'impossible de réattribuer ses préférences à un autre');
select tests.authenticate_as('alice');
select public.invite_to_club(tests.club_id('Secret MC'), tests.uid('carol'));
select tests.ok(true, 'invitations réactivées : l''invitation passe');

-- -----------------------------------------------------------------------------
-- Suppression de compte
-- -----------------------------------------------------------------------------
select tests.authenticate_as('alice');
select tests.throws('select public.delete_my_account()', 'owns_clubs_with_members',
  'un propriétaire de club avec membres doit d''abord transférer la propriété');

select tests.authenticate_as('mallory');
select public.delete_my_account();

reset role;
select tests.ok(not exists (select 1 from auth.users where email = 'mallory@test.local'),
  'le compte est supprimé');
select tests.ok(
  not exists (select 1 from public.profiles p
               where not exists (select 1 from auth.users u where u.id = p.id)),
  'le profil est supprimé avec le compte');
select tests.ok(tests.club_id('Solo') is null, 'le club sans autre membre est supprimé');
select tests.ok(
  (select member_count = 3 from public.clubs where name = 'Kin Riders'),
  'les adhésions sont retirées et les compteurs mis à jour');
select tests.ok(
  exists (select 1 from private.audit_logs where action = 'account.delete'),
  'la suppression est journalisée');

select tests.authenticate_as_anon();
select tests.throws('select public.delete_my_account()', 'permission denied',
  'un visiteur anonyme ne peut rien supprimer');

reset role;
rollback;
