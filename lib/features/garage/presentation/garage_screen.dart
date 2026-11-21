import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/garage_repository.dart';
import '../domain/garage.dart';
import 'garage_labels.dart';

/// Mon garage : motos, rappel urgent, ajout (maquette 1).
class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final motos = ref.watch(motorcyclesProvider);
    final reminders = ref.watch(remindersProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.garageTitle),
        actions: [
          IconButton(
            key: const Key('garage-reminders'),
            tooltip: l10n.garageReminders,
            onPressed: () => context.push(AppRoutes.garageReminders),
            icon: Badge(
              isLabelVisible: reminders.isNotEmpty,
              label: Text('${reminders.length}'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('garage-add'),
        heroTag: null,
        onPressed: () => context.push(AppRoutes.newMotorcycle),
        icon: const Icon(Icons.add),
        label: Text(l10n.garageAddMoto),
      ),
      body: AsyncValueView(
        value: motos,
        onRetry: () => ref.refreshGarage(),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.two_wheeler,
              title: l10n.garageEmptyTitle,
              message: l10n.garageEmptyBody,
            );
          }
          final today = DateTime.now();
          final byId = {for (final m in list) m.id: m};
          final due = [
            for (final r in reminders)
              if (byId[r.motoId] case final m?
                  when r.isDue(today, m.odometerKm))
                (r, m),
          ];
          return RefreshIndicator(
            onRefresh: () async => ref.refreshGarage(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                96,
              ),
              children: [
                Text(
                  l10n.garageSummary(list.length, due.length),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (due.isNotEmpty) ...[
                  _UrgentBanner(reminder: due.first.$1, moto: due.first.$2),
                  const SizedBox(height: AppSpacing.md),
                ],
                for (final m in list) ...[
                  m.isPrimary
                      ? _PrimaryMotoCard(
                          moto: m,
                          reminderCount: reminders
                              .where((r) => r.motoId == m.id)
                              .length,
                        )
                      : _MotoTile(moto: m),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UrgentBanner extends StatelessWidget {
  const _UrgentBanner({required this.reminder, required this.moto});

  final MaintenanceReminder reminder;
  final Motorcycle moto;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const fg = Color(0xFF7C2D12);
    return Material(
      color: const Color(0xFFFFF4E5),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: const Key('garage-urgent'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(AppRoutes.garageReminders),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_outlined, color: fg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${reminder.label ?? reminder.kind.label(l10n)} · '
                      '${reminderDue(l10n, reminder, moto.odometerKm, DateTime.now())}',
                      style: const TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(moto.name, style: const TextStyle(color: fg)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

class _MotoPhoto extends ConsumerWidget {
  const _MotoPhoto({
    required this.moto,
    required this.height,
    this.iconSize = 64,
  });

  final Motorcycle moto;
  final double height;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref
        .watch(mediaRepositoryProvider)
        ?.imageProvider(MediaBucket.garageMedia, moto.photoPath);
    final placeholder = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.marine, Color(0xFF1F3366)],
        ),
      ),
      child: Center(
        child: Icon(Icons.two_wheeler, size: iconSize, color: Colors.white38),
      ),
    );
    return SizedBox(
      height: height,
      width: double.infinity,
      child: image == null
          ? placeholder
          : Image(
              image: image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}

class _PrimaryMotoCard extends StatelessWidget {
  const _PrimaryMotoCard({required this.moto, required this.reminderCount});

  final Motorcycle moto;
  final int reminderCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget chip(String text, {Color? bg, Color? fg}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: fg),
      ),
    );
    return Card(
      key: Key('moto-${moto.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.motorcycle(moto.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                _MotoPhoto(moto: moto, height: 150, iconSize: 80),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.garagePrimary,
                      style: const TextStyle(
                        color: AppColors.marine,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          moto.name,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      Text(
                        [
                          if (moto.year != null) '${moto.year}',
                          if (moto.cc != null) '${moto.cc} cm³',
                        ].join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      chip(formatKm(moto.odometerKm)),
                      if (moto.plate != null)
                        chip(l10n.garagePlateValue(moto.plate!)),
                      if (reminderCount > 0)
                        chip(
                          l10n.garageReminderCount(reminderCount),
                          bg: const Color(0xFFFFE8D9),
                          fg: const Color(0xFF9A3412),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotoTile extends StatelessWidget {
  const _MotoTile({required this.moto});

  final Motorcycle moto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: Key('moto-${moto.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.motorcycle(moto.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 84,
                  child: _MotoPhoto(moto: moto, height: 84, iconSize: 40),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(moto.name, style: theme.textTheme.titleMedium),
                    Text(
                      [
                        if (moto.year != null) '${moto.year}',
                        if (moto.cc != null) '${moto.cc} cm³',
                        formatKm(moto.odometerKm),
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
