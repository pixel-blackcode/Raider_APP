-- =============================================================================
-- Notifications push : jetons des téléphones ; l'envoi ne bloque jamais.
-- =============================================================================
begin;

select tests.create_user(u) from unnest(array['motard', 'autre']) u;

select tests.authenticate_as('motard');
select tests.throws($$select public.register_push_token('court', 'android')$$, 'invalid_input', 'jeton trop court refusé');
select tests.throws($$select public.register_push_token(repeat('a', 40), 'windows')$$, 'invalid_input', 'plateforme inconnue refusée');
select public.register_push_token(repeat('a', 40), 'android');
select public.register_push_token(repeat('a', 40), 'android');
select tests.ok(tests.count_of('select 1 from public.push_tokens') = 1, 'jeton enregistré une seule fois');
select tests.throws($$insert into public.push_tokens (token, user_id, platform) values (repeat('b', 40), auth.uid(), 'android')$$,
  'permission denied', 'écriture directe interdite');

-- Le même téléphone passe sur un autre compte : le jeton change de propriétaire.
select tests.authenticate_as('autre');
select tests.ok(tests.count_of('select 1 from public.push_tokens') = 0, 'jetons des autres invisibles');
select public.register_push_token(repeat('a', 40), 'android');
select tests.authenticate_as('motard');
select tests.ok(tests.count_of('select 1 from public.push_tokens') = 0, 'le jeton a quitté l''ancien compte');

-- Au plus 10 téléphones par compte.
select public.register_push_token(repeat('c', 30) || g, 'android') from generate_series(10, 21) g;
select tests.ok(tests.count_of('select 1 from public.push_tokens') = 10, 'au plus 10 téléphones');

select tests.authenticate_as('autre');
select public.unregister_push_token(repeat('a', 40));
select tests.ok(tests.count_of('select 1 from public.push_tokens') = 0, 'désinscription à la déconnexion');

-- Sans pg_net ni Vault, créer une notification ne casse rien.
reset role;
insert into public.notifications (user_id, kind) values (tests.uid('motard'), 'ride_started');
select tests.ok(true, 'notification créée sans service d''envoi configuré');

select tests.authenticate_as('motard');
select tests.throws($$select public.push_secret_ok('x')$$, 'permission denied',
  'vérification du secret réservée au serveur');

rollback;
