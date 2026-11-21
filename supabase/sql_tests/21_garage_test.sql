-- =============================================================================
-- Garage : motos privées, entretiens, rappels, moto visible pendant un SOS.
-- =============================================================================
begin;

select tests.create_user(u) from unnest(array['chef', 'jean', 'curieux']) u;

-- Motos.
select tests.authenticate_as('jean');
select tests.throws($$select public.save_motorcycle(null, '', 'MT-07')$$, 'invalid_input', 'marque obligatoire');
select public.save_motorcycle(null, 'Yamaha', 'MT-07', 2021, 689, 'Noir mat', '1234ab01', 11700);
select tests.ok((select is_primary and plate = '1234AB01' from public.motorcycles where model = 'MT-07'),
  'la première moto devient principale, plaque en majuscules');
select public.save_motorcycle(null, 'Honda', 'CB 125F', 2019, 125, null, null, 24300, true);
select tests.ok((select count(*) = 1 and min(model) = 'CB 125F' from public.motorcycles where is_primary),
  'une seule moto principale');
select tests.throws($$update public.motorcycles set plate = 'X'$$, 'permission denied', 'écriture directe interdite');
select public.save_motorcycle((select id from public.motorcycles where model = 'MT-07'),
  'Yamaha', 'MT-07', 2021, 689, 'Noir mat', '1234AB01', 100, true);
select tests.ok((select is_primary and odometer_km = 11700 from public.motorcycles where model = 'MT-07'),
  'le kilométrage ne recule pas ; redevient principale');

select tests.authenticate_as('curieux');
select tests.ok(tests.count_of('select 1 from public.motorcycles') = 0, 'les motos des autres sont privées');
reset role;
select set_config('test.moto', (select id::text from public.motorcycles where model = 'MT-07'), true);
select tests.authenticate_as('curieux');
select tests.throws(format($$select public.add_maintenance(%L, 'oil', current_date)$$,
         current_setting('test.moto')), 'not_allowed', 'pas d''entretien sur la moto d''un autre');

-- Entretiens et rappel automatique.
select tests.authenticate_as('jean');
select public.add_maintenance((select id from public.motorcycles where model = 'MT-07'),
  'oil', current_date, 12000, 45, 'USD', 'Garage Matonge', 'Huile 10W-40', null, true);
select tests.ok((select odometer_km = 12000 from public.motorcycles where model = 'MT-07'),
  'le compteur avance avec l''entretien');
select tests.ok((select due_km = 15000 and due_date = (current_date + interval '6 months')::date
                   from public.maintenance_reminders where done_at is null),
  'rappel de vidange : +3 000 km ou +6 mois');
select tests.throws(format($$select public.add_maintenance(%L, 'oil', current_date, null, 10, 'EUR')$$,
         (select id from public.motorcycles where model = 'MT-07')), 'invalid_input', 'devise USD ou CDF');

-- Rappels : fait, reporté, notifié.
select public.add_reminder((select id from public.motorcycles where model = 'MT-07'),
  'insurance', 'Assurance', current_date + 5);
select tests.throws(format($$select public.add_reminder(%L, 'insurance')$$,
         (select id from public.motorcycles where model = 'MT-07')), 'invalid_input', 'date ou kilométrage requis');
select public.snooze_reminder((select id from public.maintenance_reminders where kind = 'insurance'));
select tests.ok((select due_date = current_date + 12 from public.maintenance_reminders where kind = 'insurance'),
  'reporter : +7 jours');
reset role;
update public.motorcycles set odometer_km = 14800 where model = 'MT-07';
select tests.ok(private.process_maintenance_reminders() = 1, 'vidange à 200 km : notifiée');
select tests.ok(private.process_maintenance_reminders() = 0, 'pas deux fois dans la semaine');
select tests.authenticate_as('jean');
select tests.ok((select data->>'moto' = 'Yamaha MT-07' and (data->>'km_left')::int = 200
                   from public.notifications where kind = 'maintenance_reminder'),
  'notification avec la moto et les km restants');
select public.complete_reminder((select id from public.maintenance_reminders where kind = 'oil' and done_at is null));
select tests.ok((select due_km = 17800 from public.maintenance_reminders where kind = 'oil' and done_at is null),
  'rappel répétable : le suivant est créé');

-- La moto dans le SOS : visible des participants pendant l'alerte seulement.
select tests.authenticate_as('chef');
select public.create_ride('Sortie test', now() + interval '1 day', 'Kinshasa', 'A1', 'B1', 'public', 'open', p_publish => true);
select tests.authenticate_as('jean');
select public.join_ride(tests.ride_id('Sortie test'));
select public.save_motorcycle((select id from public.motorcycles where model = 'MT-07'),
  'Yamaha', 'MT-07', 2021, 689, 'Noir mat', '1234AB01', 14800, true, true);
select tests.authenticate_as('chef');
select public.set_ride_status(tests.ride_id('Sortie test'), 'start');
select tests.authenticate_as('jean');
select public.raise_sos(tests.ride_id('Sortie test'), 'breakdown', gen_random_uuid());
select tests.authenticate_as('chef');
select tests.ok((select plate = '1234AB01' and model = 'MT-07'
                   from public.sos_motorcycle((select id from public.sos_alerts))),
  'pendant le SOS, l''organisateur voit la moto');
select tests.ok(tests.count_of('select 1 from public.motorcycles') = 0, 'mais pas le garage de Jean');
select tests.authenticate_as('curieux');
select tests.ok(tests.count_of(format('select 1 from public.sos_motorcycle(%L)', (select id from public.sos_alerts where true limit 1))) = 0,
  'un motard hors balade ne voit rien');
select tests.authenticate_as('jean');
select public.close_sos((select id from public.sos_alerts), 'resolved');
select tests.authenticate_as('chef');
select tests.ok(tests.count_of(format('select 1 from public.sos_motorcycle(%L)',
                 (select id from public.sos_alerts))) = 0, 'alerte close : la moto n''est plus visible');

-- Suppression.
select tests.authenticate_as('jean');
select public.delete_motorcycle((select id from public.motorcycles where model = 'MT-07'));
select tests.ok((select count(*) = 1 and bool_and(is_primary) from public.motorcycles),
  'moto supprimée ; l''autre redevient principale');
select tests.ok(tests.count_of('select 1 from public.maintenance_records') = 0, 'son historique est supprimé');

rollback;
