-- =============================================================================
-- Marketplace (critère 14 : aucun paiement intégré) et recherche tolérante.
-- =============================================================================
begin;

select tests.create_user('vendeur', '{"username": "vendeur", "display_name": "Jean Phoenix"}');
select tests.create_user('acheteur', '{"username": "acheteur", "display_name": "Acheteur"}');
select tests.create_user('curieux', '{"username": "curieux", "display_name": "Curieux"}');

-- Critère 14 : aucune table ni fonction de paiement.
select tests.ok(not exists (
  select 1 from information_schema.tables
   where table_schema = 'public'
     and (table_name ilike '%payment%' or table_name ilike '%order%' or table_name ilike '%cart%'
          or table_name ilike '%checkout%' or table_name ilike '%transaction%')),
  'aucune table de paiement, panier ou commande');

-- Création avec photos (fichiers réellement envoyés dans son dossier).
select tests.authenticate_as('vendeur');
insert into storage.objects (bucket_id, name)
select 'listing-media', tests.uid('vendeur') || '/l' || g || '.jpg' from generate_series(1, 11) g;
select public.create_listing('00000000-0000-4000-8000-0000000000b1', 'helmet', 'Casque intégral LS2',
  'good', 'Kinshasa', 'Taille M, très bon état', 80, 'USD', 'Gombe',
  array[tests.uid('vendeur') || '/l1.jpg', tests.uid('vendeur') || '/l2.jpg']);
select public.create_listing('00000000-0000-4000-8000-0000000000b1', 'helmet', 'Casque intégral LS2',
  'good', 'Kinshasa');
select tests.ok(tests.count_of('select 1 from public.listings') = 1, 'création idempotente');
select tests.throws(
  format($$select public.create_listing(gen_random_uuid(), 'parts', 'Trop de photos', 'good', 'Kinshasa',
           p_media_paths => array(select %L || '/l' || g || '.jpg' from generate_series(1, 11) g))$$,
         tests.uid('vendeur')),
  'invalid_input', 'au plus 10 photos');
select tests.throws(
  $$select public.create_listing(gen_random_uuid(), 'parts', 'Photo absente', 'good', 'Kinshasa',
      p_media_paths => array[tests.uid('vendeur') || '/absente.jpg'])$$,
  'invalid_input', 'photo non envoyée refusée');
select tests.throws($$select public.create_listing(gen_random_uuid(), 'parts', 'X', 'good', 'Kinshasa')$$,
  'invalid_input', 'titre trop court refusé');
select tests.throws($$select public.create_listing(gen_random_uuid(), 'parts', 'Prix négatif', 'good', 'Kinshasa', p_price => -5)$$,
  'invalid_input', 'prix négatif refusé');
select public.create_listing(gen_random_uuid(), 'motorcycle', 'Honda CG 125 Phoenix', 'fair', 'Lubumbashi',
  'Moto robuste', 950, 'USD');
select public.create_listing(gen_random_uuid(), 'parts', 'Pneu arrière', 'new', 'Kinshasa',
  p_price => 120000, p_currency => 'CDF');

-- Visibilité, filtres, recherche tolérante.
select tests.authenticate_as('acheteur');
select tests.ok(tests.count_of('select 1 from public.search_listings()') = 3, 'annonces visibles des motards connectés');
select tests.ok(tests.count_of($$select 1 from public.search_listings(p_category => 'helmet')$$) = 1, 'filtre par catégorie');
select tests.ok(tests.count_of($$select 1 from public.search_listings(p_max_price => 100, p_currency => 'USD')$$) = 1, 'filtre par prix et devise');
select tests.ok(tests.count_of($$select 1 from public.search_listings(p_city => 'lubumbashi')$$) = 1, 'filtre par ville (casse ignorée)');
select tests.ok(tests.count_of($$select 1 from public.search_listings('casque')$$) = 1, 'recherche simple');
select tests.ok(tests.count_of($$select 1 from public.search_listings('fenix')$$) = 1, 'recherche tolérante : « fenix » trouve « Phoenix »');
select tests.ok(tests.count_of($$select 1 from public.search_listings('pneux arriere')$$) = 1, 'recherche tolérante : faute et accent');
select tests.ok((select cardinality(media_paths) = 2 from public.search_listings('casque')), 'photos de l''annonce');
select tests.ok(tests.count_of($$select 1 from storage.objects where bucket_id = 'listing-media'$$) = 2,
  'seules les photos rattachées à une annonce sont lisibles');
select tests.authenticate_as_anon();
select tests.throws('select count(*) from public.listings', 'permission denied', 'anonyme : aucun accès');

-- Favoris.
select tests.authenticate_as('acheteur');
select public.set_listing_favorite((select id from public.search_listings('casque')), true);
select public.set_listing_favorite((select id from public.search_listings('casque')), true);
select tests.ok(tests.count_of('select 1 from public.search_listings(p_favorites_only => true)') = 1, 'favoris');
select tests.ok((select is_favorite and favorite_count = 1 from public.search_listings('casque')), 'favori signalé et compté');
select public.set_listing_favorite((select id from public.search_listings('casque')), false);
select tests.ok(tests.count_of('select 1 from public.search_listings(p_favorites_only => true)') = 0, 'retrait du favori');

-- Seul le vendeur modifie, change le statut, supprime.
select tests.throws(format($$select public.set_listing_status(%L, 'sold')$$, (select id from public.search_listings('casque'))),
  'not_allowed', 'un autre motard ne change pas le statut');
select tests.throws(
  $$update public.listings set price = 1$$, 'permission denied', 'aucune écriture directe');
select tests.authenticate_as('vendeur');
select public.set_listing_status((select id from public.search_listings('casque')), 'sold');
select tests.authenticate_as('acheteur');
select tests.ok(tests.count_of($$select 1 from public.search_listings('casque')$$) = 0, 'annonce vendue retirée de la recherche');
select tests.ok(tests.count_of($$select 1 from public.search_listings('casque', p_include_sold => true)$$) = 1, 'vendue encore consultable sur demande');
select tests.authenticate_as('vendeur');
select tests.ok(
  (select public.update_listing(id, 'helmet', 'Casque LS2 taille M', 'good', 'Kinshasa',
     p_media_paths => array[tests.uid('vendeur') || '/l2.jpg'])
     from public.search_listings('casque', p_include_sold => true))
  = array[tests.uid('vendeur') || '/l1.jpg'],
  'modification : photo retirée renvoyée pour nettoyage');

-- Blocage : annonces masquées.
select tests.authenticate_as('curieux');
select public.block_user(tests.uid('vendeur'));
select tests.ok(tests.count_of('select 1 from public.search_listings()') = 0, 'annonces d''un motard bloqué masquées');
select public.unblock_user(tests.uid('vendeur'));

-- Signalement : 3 signalements masquent l'annonce ; l'administrateur rétablit.
reset role;
select tests.create_user('temoin');
insert into private.platform_admins (user_id) values (tests.create_user('admin'));
create temp table l as select id from public.listings where title = 'Pneu arrière';
grant select on l to authenticated;
select tests.authenticate_as('vendeur');
select tests.throws(format($$select public.report_content('listing', %L, 'spam')$$, (select id from l)),
  'not_allowed', 'on ne signale pas sa propre annonce');
select tests.authenticate_as('acheteur');
select public.report_content('listing', (select id from l), 'scam');
select tests.authenticate_as('curieux');
select public.report_content('listing', (select id from l), 'scam');
select tests.authenticate_as('temoin');
select public.report_content('listing', (select id from l), 'spam');
select tests.ok(tests.count_of('select 1 from public.search_listings(''pneu'')') = 0, '3 signalements : annonce masquée');
select tests.authenticate_as('admin');
select tests.ok((select preview = 'Pneu arrière' and report_count = 3 from public.moderation_queue()), 'file de modération : annonce');
select public.moderate_content('listing', (select id from l), 'restore');
select tests.authenticate_as('acheteur');
select tests.ok(tests.count_of('select 1 from public.search_listings(''pneu'')') = 1, 'annonce rétablie');

-- Suppression : chemins des photos renvoyés.
select tests.authenticate_as('vendeur');
select tests.ok(
  (select public.delete_listing(id) from public.listings where title = 'Casque LS2 taille M')
  = array[tests.uid('vendeur') || '/l2.jpg'],
  'suppression : photos à effacer');

-- Recherche tolérante de motards et de clubs.
select tests.authenticate_as('acheteur');
select tests.ok(tests.count_of($$select 1 from public.search_riders('fenix')$$) = 1, 'motard trouvé malgré l''orthographe');
select tests.ok(tests.count_of($$select 1 from public.search_riders('jean phoen')$$) = 1, 'motard trouvé par début de nom');
select tests.ok(tests.count_of($$select 1 from public.search_riders('@vendeur')$$) = 1, 'motard trouvé par pseudonyme');
select tests.ok(tests.count_of($$select 1 from public.search_riders('a')$$) = 0, 'au moins 2 caractères');
select public.create_club('Phoenix Riders', 'Kinshasa', 'public', 'open');
select tests.ok(tests.count_of($$select 1 from public.search_clubs('fenix riderz')$$) = 1, 'club trouvé malgré les fautes');

-- Publications : jusqu'à 10 photos.
select tests.authenticate_as('vendeur');
insert into storage.objects (bucket_id, name)
select 'post-media', tests.uid('vendeur') || '/p' || g || '.jpg' from generate_series(1, 11) g;
select public.create_post(gen_random_uuid(), 'Dix photos',
  p_media_paths => array(select tests.uid('vendeur') || '/p' || g || '.jpg' from generate_series(1, 10) g));
select tests.ok(tests.count_of('select 1 from public.post_media') = 10, 'publication avec 10 photos');
select tests.throws(
  $$select public.create_post(gen_random_uuid(), 'Onze',
      p_media_paths => array(select tests.uid('vendeur') || '/p' || g || '.jpg' from generate_series(1, 11) g))$$,
  'invalid_input', 'pas plus de 10 photos');

rollback;
