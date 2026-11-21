import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/router/app_router.dart';
import 'package:rider_group/app/router/app_routes.dart';
import 'package:rider_group/features/garage/domain/garage.dart';

import '../../helpers/fakes.dart';
import '../../helpers/signed_in_app.dart';

Future<void> go(
  WidgetTester tester,
  ProviderContainer container,
  String path,
) async {
  unawaited(container.read(routerProvider).push(path));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ajouter sa première moto depuis le Profil', (tester) async {
    final garage = FakeGarageRepository();
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      garage: garage,
    );
    await go(tester, container, AppRoutes.profile);
    final tile = find.byKey(const Key('profile-garage'));
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.text('Votre garage est vide'), findsOneWidget);

    await tester.tap(find.byKey(const Key('garage-add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('moto-brand')), 'Yamaha');
    await tester.enterText(find.byKey(const Key('moto-model')), 'MT-07');
    await tester.enterText(find.byKey(const Key('moto-plate')), '1234ab01');
    await tester.enterText(find.byKey(const Key('moto-km')), '11700');
    final save = find.byKey(const Key('moto-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(garage.calls, ['save:Yamaha MT-07:1234ab01:11700']);
    expect(find.byKey(const Key('moto-name')), findsOneWidget);
    expect(garage.motos.values.single.isPrimary, isTrue);
  });

  testWidgets('entretien : vidange avec coût en CDF et rappel', (tester) async {
    final garage = FakeGarageRepository();
    final id = await garage.saveMotorcycle(
      null,
      const MotorcycleDraft(brand: 'Yamaha', model: 'MT-07', odometerKm: 11700),
    );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      garage: garage,
    );
    await go(tester, container, AppRoutes.motorcycle(id));
    await tester.tap(find.byKey(const Key('moto-add-maintenance')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('maintenance-km')), '12000');
    await tester.enterText(find.byKey(const Key('maintenance-cost')), '180000');
    await tester.tap(find.text('CDF'));
    await tester.pumpAndSettle();
    final save = find.byKey(const Key('maintenance-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(garage.calls.last, 'maintenance:oil:12000:180000.0:true');
    expect(find.text('180 000 FC'), findsOneWidget);
  });

  testWidgets('rappel urgent : bandeau, puis « Reporter »', (tester) async {
    final garage = FakeGarageRepository();
    final id = await garage.saveMotorcycle(
      null,
      const MotorcycleDraft(brand: 'Yamaha', model: 'MT-07', odometerKm: 14800),
    );
    await garage.addReminder(id, MaintenanceKind.oil, dueKm: 15000);
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      garage: garage,
    );
    await go(tester, container, AppRoutes.garage);
    expect(find.byKey(const Key('garage-urgent')), findsOneWidget);
    expect(find.textContaining('dans 200 km'), findsOneWidget);
    await tester.tap(find.byKey(const Key('garage-urgent')));
    await tester.pumpAndSettle();
    final rid = garage.reminderList.single.id;
    await tester.tap(find.byKey(Key('reminder-snooze-$rid')));
    await tester.pumpAndSettle();
    expect(garage.calls.last, 'snooze:$rid');
  });

  testWidgets('supprimer une moto', (tester) async {
    final garage = FakeGarageRepository();
    final id = await garage.saveMotorcycle(
      null,
      const MotorcycleDraft(brand: 'Honda', model: 'CB 125F'),
    );
    final container = await pumpOnlineApp(
      tester,
      auth: signedInAs(alice),
      garage: garage,
    );
    await go(tester, container, AppRoutes.motorcycle(id));
    await tester.tap(find.byKey(const Key('moto-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('moto-menu-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer').last);
    await tester.pumpAndSettle();
    expect(garage.motos, isEmpty);
  });
}
