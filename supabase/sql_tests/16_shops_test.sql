-- =============================================================================
-- Boutiques des motards vérifiés (sans paiement).
-- =============================================================================
begin;

select tests.create_user(u) from unnest(array['vendeur', 'autre', 'client', 'equipe']) u;
insert into private.platform_admins (user_id) values (tests.uid('equipe'));

select tests.authenticate_as('vendeur');
select tests.throws($$select public.save_my_shop('Moto Pièces Kin', 'Kinshasa')$$,
  'verification_required', 'boutique réservée aux motards vérifiés');

reset role;
update public.profiles set verified_at = now(), verified_until = now() + interval '1 year'
 where id in (tests.uid('vendeur'), tests.uid('autre'));

select tests.authenticate_as('vendeur');
select tests.throws($$select public.save_my_shop('Mo', 'Kinshasa')$$, 'invalid_input', 'nom trop court');
select tests.throws($$select public.save_my_shop('Moto Pièces Kin', 'Kinshasa', '', null, 'abc')$$,
  'invalid_input', 'numéro invalide');
select public.save_my_shop('Moto Pièces Kin', 'Kinshasa', 'Pièces et casques', 'Gombe', '+243 81 000 0000');
select public.save_my_shop('Moto Pièces Kin', 'Kinshasa', 'Pièces, casques, gants', 'Gombe', '+243810000000');
select tests.ok((select count(*) = 1 and min(description) = 'Pièces, casques, gants' from public.shops),
  'une seule boutique, modifiable');
select tests.throws($$update public.shops set name = 'X'$$, 'permission denied', 'écriture directe interdite');
select public.create_listing(gen_random_uuid(), 'helmet', 'Casque intégral', 'good', 'Kinshasa');
insert into storage.objects (bucket_id, name) values ('shop-media', tests.uid('vendeur') || '/logo.png');
select public.set_my_shop_logo(tests.uid('vendeur') || '/logo.png');

select tests.authenticate_as('autre');
select tests.throws($$select public.save_my_shop('moto pièces kin', 'Lubumbashi')$$,
  'shop_name_taken', 'nom déjà pris');
select tests.throws(
  format($$insert into storage.objects (bucket_id, name) values ('shop-media', %L)$$,
         tests.uid('vendeur') || '/faux.png'),
  'row-level security', 'pas de dépôt dans le dossier d''un autre');

select tests.authenticate_as('client');
select tests.ok((select active and listing_count = 1 and phone = '+243810000000'
                   and logo_path is not null from public.list_shops('moto piece')),
  'boutique visible et trouvée (recherche tolérante)');

-- Fin de vérification : la boutique disparaît pour les autres, reste pour soi.
reset role;
update public.profiles set verified_at = null, verified_until = null where id = tests.uid('vendeur');
select tests.authenticate_as('client');
select tests.ok(tests.count_of('select 1 from public.list_shops()') = 0,
  'boutique masquée quand le propriétaire n''est plus vérifié');
select tests.authenticate_as('vendeur');
select tests.ok((select not active from public.list_shops(p_owner_id => tests.uid('vendeur'))),
  'le propriétaire voit sa boutique inactive');

-- Suspension par l'équipe.
reset role;
update public.profiles set verified_at = now(), verified_until = now() + interval '1 year'
 where id = tests.uid('vendeur');
select tests.authenticate_as('client');
select tests.throws(format($$select public.set_shop_suspended(%L, true)$$, (select id from public.shops)),
  'not_allowed', 'seule l''équipe suspend');
select tests.authenticate_as('equipe');
select public.set_shop_suspended((select id from public.shops), true, 'Annonces trompeuses');
select tests.ok((select suspended and not active from public.list_shops()),
  'l''équipe voit la boutique suspendue');
select tests.authenticate_as('client');
select tests.ok(tests.count_of('select 1 from public.list_shops()') = 0, 'boutique suspendue masquée');
select tests.authenticate_as('vendeur');
select tests.ok((select data->>'note' = 'Annonces trompeuses' from public.notifications
                  where kind = 'shop_suspended'), 'le propriétaire est prévenu avec la raison');
select tests.ok((select suspended from public.list_shops(p_owner_id => tests.uid('vendeur'))),
  'le propriétaire voit sa boutique suspendue');
select tests.authenticate_as('equipe');
select public.set_shop_suspended((select id from public.shops), false);
select tests.authenticate_as('client');
select tests.ok(tests.count_of('select 1 from public.list_shops()') = 1, 'boutique rétablie visible');

select tests.authenticate_as('vendeur');
select public.delete_my_shop();
select tests.ok(tests.count_of('select 1 from public.shops') = 0, 'boutique fermée');

rollback;
