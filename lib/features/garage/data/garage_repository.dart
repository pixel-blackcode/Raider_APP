import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/garage.dart';

abstract interface class GarageRepository {
  Future<List<Motorcycle>> motorcycles();

  /// Crée (id null) ou modifie une moto ; retourne son identifiant.
  Future<String> saveMotorcycle(String? id, MotorcycleDraft draft);

  /// Retourne l'ancienne photo (à effacer).
  Future<String?> setPhoto(String motoId, String? path);

  /// Retourne les fichiers à effacer (photo, factures).
  Future<List<String>> deleteMotorcycle(String motoId);

  Future<List<MaintenanceRecord>> records(String motoId);

  Future<void> addMaintenance(String motoId, MaintenanceDraft draft);

  /// Retourne la facture à effacer.
  Future<String?> deleteMaintenance(String recordId);

  /// Rappels en cours, toutes motos.
  Future<List<MaintenanceReminder>> reminders();

  Future<void> addReminder(
    String motoId,
    MaintenanceKind kind, {
    String? label,
    DateTime? dueDate,
    int? dueKm,
  });

  Future<void> completeReminder(String id);

  Future<void> snoozeReminder(String id);

  Future<void> deleteReminder(String id);

  /// Moto de l'auteur d'une alerte SOS active (null si non partagée).
  Future<SosMotorcycle?> sosMotorcycle(String alertId);
}

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class SupabaseGarageRepository implements GarageRepository {
  SupabaseGarageRepository(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  static const _motoColumns =
      'id, brand, model, year, cc, color, plate, odometer_km, is_primary, '
      'show_in_sos, photo_path';

  @override
  Future<List<Motorcycle>> motorcycles() => _guard(() async {
    final rows = await _client
        .from('motorcycles')
        .select(_motoColumns)
        .order('is_primary', ascending: false)
        .order('created_at');
    return rows.map(Motorcycle.fromJson).toList();
  });

  @override
  Future<String> saveMotorcycle(String? id, MotorcycleDraft d) => _guard(
    () => _client.rpc<String>(
      'save_motorcycle',
      params: {
        'p_id': id,
        'p_brand': d.brand.trim(),
        'p_model': d.model.trim(),
        'p_year': d.year,
        'p_cc': d.cc,
        'p_color': d.color,
        'p_plate': d.plate,
        'p_odometer_km': d.odometerKm,
        'p_is_primary': d.isPrimary,
        'p_show_in_sos': d.showInSos,
      },
    ),
  );

  @override
  Future<String?> setPhoto(String motoId, String? path) => _guard(
    () => _client.rpc<String?>(
      'set_motorcycle_photo',
      params: {'p_id': motoId, 'p_path': path},
    ),
  );

  @override
  Future<List<String>> deleteMotorcycle(String motoId) => _guard(() async {
    final data = await _client.rpc<Object?>(
      'delete_motorcycle',
      params: {'p_id': motoId},
    );
    return [for (final p in (data as List?) ?? const []) p as String];
  });

  @override
  Future<List<MaintenanceRecord>> records(String motoId) => _guard(() async {
    final rows = await _client
        .from('maintenance_records')
        .select()
        .eq('moto_id', motoId)
        .order('done_on', ascending: false)
        .limit(200);
    return rows.map(MaintenanceRecord.fromJson).toList();
  });

  @override
  Future<void> addMaintenance(String motoId, MaintenanceDraft d) => _guard(
    () => _client.rpc<Object?>(
      'add_maintenance',
      params: {
        'p_moto_id': motoId,
        'p_kind': d.kind.name,
        'p_done_on': _date(d.doneOn),
        'p_odometer_km': d.odometerKm,
        'p_cost': d.cost,
        'p_currency': d.currency == GarageCurrency.cdf ? 'CDF' : 'USD',
        'p_garage': d.garage,
        'p_note': d.note,
        'p_invoice_path': d.invoicePath,
        'p_remind_next': d.remindNext,
      },
    ),
  );

  @override
  Future<String?> deleteMaintenance(String recordId) => _guard(
    () =>
        _client.rpc<String?>('delete_maintenance', params: {'p_id': recordId}),
  );

  @override
  Future<List<MaintenanceReminder>> reminders() => _guard(() async {
    final rows = await _client
        .from('maintenance_reminders')
        .select()
        .isFilter('done_at', null)
        .order('due_date', nullsFirst: false);
    return rows.map(MaintenanceReminder.fromJson).toList();
  });

  @override
  Future<void> addReminder(
    String motoId,
    MaintenanceKind kind, {
    String? label,
    DateTime? dueDate,
    int? dueKm,
  }) => _guard(
    () => _client.rpc<Object?>(
      'add_reminder',
      params: {
        'p_moto_id': motoId,
        'p_kind': kind.name,
        'p_label': label,
        'p_due_date': dueDate == null ? null : _date(dueDate),
        'p_due_km': dueKm,
      },
    ),
  );

  @override
  Future<void> completeReminder(String id) => _guard(
    () => _client.rpc<void>('complete_reminder', params: {'p_id': id}),
  );

  @override
  Future<void> snoozeReminder(String id) =>
      _guard(() => _client.rpc<void>('snooze_reminder', params: {'p_id': id}));

  @override
  Future<void> deleteReminder(String id) =>
      _guard(() => _client.rpc<void>('delete_reminder', params: {'p_id': id}));

  @override
  Future<SosMotorcycle?> sosMotorcycle(String alertId) => _guard(() async {
    final data = await _client.rpc<Object?>(
      'sos_motorcycle',
      params: {'p_alert_id': alertId},
    );
    final rows = (data as List?) ?? const [];
    return rows.isEmpty
        ? null
        : SosMotorcycle.fromJson(rows.first as Map<String, dynamic>);
  });
}

final garageRepositoryProvider = Provider<GarageRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseGarageRepository(client);
});

final motorcyclesProvider = FutureProvider.autoDispose<List<Motorcycle>>((
  ref,
) async {
  final repo = ref.watch(garageRepositoryProvider);
  if (repo == null || ref.watch(currentUserIdProvider) == null) {
    return const [];
  }
  return repo.motorcycles();
});

final maintenanceRecordsProvider = FutureProvider.autoDispose
    .family<List<MaintenanceRecord>, String>((ref, motoId) async {
      final repo = ref.watch(garageRepositoryProvider);
      if (repo == null) return const [];
      return repo.records(motoId);
    });

final remindersProvider = FutureProvider.autoDispose<List<MaintenanceReminder>>(
  (ref) async {
    final repo = ref.watch(garageRepositoryProvider);
    if (repo == null || ref.watch(currentUserIdProvider) == null) {
      return const [];
    }
    return repo.reminders();
  },
);

final sosMotorcycleProvider = FutureProvider.autoDispose
    .family<SosMotorcycle?, String>((ref, alertId) async {
      final repo = ref.watch(garageRepositoryProvider);
      if (repo == null) return null;
      try {
        return await repo.sosMotorcycle(alertId);
      } catch (_) {
        return null; // la moto est un complément : jamais bloquant
      }
    });

extension RefreshGarage on WidgetRef {
  void refreshGarage([String? motoId]) {
    invalidate(motorcyclesProvider);
    invalidate(remindersProvider);
    if (motoId != null) invalidate(maintenanceRecordsProvider(motoId));
  }
}
