import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/photo_viewer.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../community/presentation/community_ui.dart';
import '../data/garage_repository.dart';
import '../domain/garage.dart';
import 'garage_labels.dart';

/// Fiche d'une moto : chiffres, rappels, historique (maquette 3).
class MotoDetailScreen extends ConsumerWidget {
  const MotoDetailScreen({super.key, required this.motoId});

  final String motoId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Motorcycle m,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.garageDeleteMotoTitle,
      message: l10n.garageDeleteMotoBody(m.name),
      confirmLabel: l10n.actionDelete,
    );
    if (!ok || !context.mounted) return;
    try {
      final files = await ref
          .read(garageRepositoryProvider)!
          .deleteMotorcycle(m.id);
      if (files.isNotEmpty) {
        await ref
            .read(mediaRepositoryProvider)
            ?.remove(MediaBucket.garageMedia, files);
      }
      ref.refreshGarage();
      if (context.mounted) context.pop();
    } catch (error) {
      if (context.mounted) showSnack(context, describeError(context, error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final motos = ref.watch(motorcyclesProvider);
    return Scaffold(
      body: AsyncValueView(
        value: motos,
        onRetry: () => ref.refreshGarage(motoId),
        data: (list) {
          final m = list.where((x) => x.id == motoId).firstOrNull;
          if (m == null) {
            return Scaffold(
              appBar: AppBar(),
              body: EmptyState(
                icon: Icons.two_wheeler,
                title: l10n.garageMotoNotFound,
                message: '',
              ),
            );
          }
          final reminders = [
            for (final r
                in ref.watch(remindersProvider).value ??
                    const <MaintenanceReminder>[])
              if (r.motoId == m.id) r,
          ];
          final records = ref.watch(maintenanceRecordsProvider(m.id));
          final photo = ref
              .watch(mediaRepositoryProvider)
              ?.imageProvider(MediaBucket.garageMedia, m.photoPath);
          final today = DateTime.now();
          Widget stat(String value, String label) => Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Text(value, style: theme.textTheme.titleLarge),
                    Text(label, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          );
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppColors.marine,
                foregroundColor: Colors.white,
                actions: [
                  PopupMenuButton<String>(
                    key: const Key('moto-menu'),
                    onSelected: (v) => v == 'edit'
                        ? context.push(AppRoutes.editMotorcycle(m.id))
                        : _delete(context, ref, m),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(l10n.actionEdit),
                      ),
                      PopupMenuItem(
                        key: const Key('moto-menu-delete'),
                        value: 'delete',
                        child: Text(l10n.actionDelete),
                      ),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: GestureDetector(
                    onTap: photo == null
                        ? null
                        : () => openPhotoViewer(context, images: [photo]),
                    child: photo == null
                        ? const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.marine, Color(0xFF1F3366)],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.two_wheeler,
                                size: 110,
                                color: Colors.white30,
                              ),
                            ),
                          )
                        : Image(image: photo, fit: BoxFit.cover),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList.list(
                  children: [
                    Text(
                      m.name,
                      key: const Key('moto-name'),
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text(
                      [
                        if (m.color != null) m.color!,
                        if (m.plate != null) l10n.garagePlateValue(m.plate!),
                      ].join(' · '),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        stat(
                          formatKm(m.odometerKm).replaceAll(' km', ''),
                          'km',
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        stat(m.cc == null ? '—' : '${m.cc}', 'cm³'),
                        const SizedBox(width: AppSpacing.sm),
                        stat(
                          m.year == null ? '—' : '${m.year}',
                          l10n.garageYearShort,
                        ),
                      ],
                    ),
                    SectionHeader(
                      title: l10n.garageNextReminders,
                      trailing: TextButton(
                        onPressed: () =>
                            context.push(AppRoutes.garageReminders),
                        child: Text(l10n.homeSeeAll),
                      ),
                    ),
                    if (reminders.isEmpty)
                      Text(
                        l10n.garageNoReminders,
                        style: theme.textTheme.bodySmall,
                      )
                    else
                      for (final r in reminders.take(3))
                        Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.circle,
                              size: 12,
                              color: r.isDue(today, m.odometerKm)
                                  ? AppColors.brand
                                  : AppColors.gold,
                            ),
                            title: Text(r.label ?? r.kind.label(l10n)),
                            subtitle: Text(
                              reminderDue(l10n, r, m.odometerKm, today),
                            ),
                          ),
                        ),
                    SectionHeader(title: l10n.garageHistory),
                    AsyncValueView(
                      value: records,
                      data: (items) => items.isEmpty
                          ? Text(
                              l10n.garageNoHistory,
                              style: theme.textTheme.bodySmall,
                            )
                          : Card(
                              child: Column(
                                children: [
                                  for (final r in items)
                                    ListTile(
                                      key: Key('record-${r.id}'),
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(
                                          0xFFFFE8D9,
                                        ),
                                        foregroundColor: const Color(
                                          0xFFC2410C,
                                        ),
                                        child: Icon(r.kind.icon),
                                      ),
                                      title: Text(r.kind.label(l10n)),
                                      subtitle: Text(
                                        [
                                          MaterialLocalizations.of(context)
                                              .formatMediumDate(r.doneOn),
                                          if (r.odometerKm != null)
                                            formatKm(r.odometerKm!),
                                          if (r.garage != null) r.garage!,
                                        ].join(' · '),
                                      ),
                                      trailing: r.cost == null
                                          ? null
                                          : Text(
                                              formatCost(r.cost!, r.currency),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                      onLongPress: () async {
                                        final ok = await showConfirmDialog(
                                          context,
                                          title: l10n.garageDeleteRecord,
                                          message: r.kind.label(l10n),
                                          confirmLabel: l10n.actionDelete,
                                        );
                                        if (!ok) return;
                                        final file = await ref
                                            .read(garageRepositoryProvider)!
                                            .deleteMaintenance(r.id);
                                        if (file != null) {
                                          await ref
                                              .read(mediaRepositoryProvider)
                                              ?.remove(
                                                MediaBucket.garageMedia,
                                                [file],
                                              );
                                        }
                                        ref.refreshGarage(m.id);
                                      },
                                    ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('moto-add-maintenance'),
        heroTag: null,
        onPressed: () => context.push(AppRoutes.addMaintenance(motoId)),
        icon: const Icon(Icons.add),
        label: Text(l10n.garageAddMaintenance),
      ),
    );
  }
}
