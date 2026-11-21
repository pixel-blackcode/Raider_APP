import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../community/presentation/community_ui.dart';
import '../data/garage_repository.dart';
import '../domain/garage.dart';
import 'garage_labels.dart';

/// Rappels d'entretien de toutes les motos (maquette 5).
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(GarageRepository r) action,
  ) async {
    try {
      await action(ref.read(garageRepositoryProvider)!);
      ref.refreshGarage();
    } catch (error) {
      if (context.mounted) showSnack(context, describeError(context, error));
    }
  }

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    List<Motorcycle> motos,
  ) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AddReminderSheet(motos: motos),
    );
    if (created == true) ref.refreshGarage();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final motos = ref.watch(motorcyclesProvider).value ?? const <Motorcycle>[];
    final byId = {for (final m in motos) m.id: m};
    final today = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.garageReminders),
        actions: [
          if (motos.isNotEmpty)
            IconButton(
              key: const Key('reminder-add'),
              tooltip: l10n.garageAddReminder,
              onPressed: () => _add(context, ref, motos),
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: AsyncValueView(
        value: ref.watch(remindersProvider),
        onRetry: () => ref.refreshGarage(),
        data: (list) {
          final items = [
            for (final r in list)
              if (byId[r.motoId] case final m?) (r, m),
          ];
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.notifications_none,
              title: l10n.garageNoReminders,
              message: l10n.garageRemindersHelp,
            );
          }
          final due = [
            for (final x in items)
              if (x.$1.isDue(today, x.$2.odometerKm)) x,
          ];
          final later = [
            for (final x in items)
              if (!x.$1.isDue(today, x.$2.odometerKm)) x,
          ];
          Widget item(
            (MaintenanceReminder, Motorcycle) x, {
            required bool urgent,
          }) {
            final (r, m) = x;
            return Card(
              key: Key('reminder-${r.id}'),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: urgent
                              ? const Color(0xFFFFE8D9)
                              : theme.colorScheme.surfaceContainerHighest,
                          foregroundColor: urgent
                              ? const Color(0xFFC2410C)
                              : AppColors.marine,
                          child: Icon(r.kind.icon),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.label ?? r.kind.label(l10n),
                                style: theme.textTheme.titleSmall,
                              ),
                              Text(
                                '${m.name} · ${reminderDue(l10n, r, m.odometerKm, today)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (_) =>
                              _run(context, ref, (g) => g.deleteReminder(r.id)),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l10n.actionDelete),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (urgent) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              key: Key('reminder-done-${r.id}'),
                              onPressed: () {
                                if (MaintenanceKind.forRecords.contains(
                                  r.kind,
                                )) {
                                  context.push(AppRoutes.addMaintenance(m.id));
                                } else {
                                  _run(
                                    context,
                                    ref,
                                    (g) => g.completeReminder(r.id),
                                  );
                                }
                              },
                              child: Text(l10n.garageDone),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton(
                              key: Key('reminder-snooze-${r.id}'),
                              onPressed: () => _run(
                                context,
                                ref,
                                (g) => g.snoozeReminder(r.id),
                              ),
                              child: Text(l10n.garageSnooze),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (due.isNotEmpty) ...[
                SectionHeader(title: l10n.garageDueSoon),
                for (final x in due) item(x, urgent: true),
              ],
              if (later.isNotEmpty) ...[
                SectionHeader(title: l10n.garageUpcoming),
                for (final x in later) item(x, urgent: false),
              ],
              const SizedBox(height: AppSpacing.md),
              InfoCard(
                icon: Icons.info_outline,
                message: l10n.garageRemindersHelp,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AddReminderSheet extends ConsumerStatefulWidget {
  const _AddReminderSheet({required this.motos});

  final List<Motorcycle> motos;

  @override
  ConsumerState<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<_AddReminderSheet> {
  late String _moto = widget.motos.first.id;
  MaintenanceKind _kind = MaintenanceKind.insurance;
  DateTime? _date;
  final _km = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _km.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final km = int.tryParse(_km.text);
    if (_date == null && km == null) {
      showSnack(context, l10n.garageReminderNeedsDue);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(garageRepositoryProvider)!
          .addReminder(_moto, _kind, dueDate: _date, dueKm: km);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final m = MaterialLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.garageAddReminder,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (widget.motos.length > 1)
            DropdownButtonFormField<String>(
              initialValue: _moto,
              decoration: InputDecoration(labelText: l10n.garageMoto),
              items: [
                for (final x in widget.motos)
                  DropdownMenuItem(value: x.id, child: Text(x.name)),
              ],
              onChanged: (v) => setState(() => _moto = v ?? _moto),
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final k in MaintenanceKind.values)
                ChoiceChip(
                  key: Key('reminder-kind-${k.name}'),
                  label: Text(k.label(l10n)),
                  selected: _kind == k,
                  onSelected: (_) => setState(() => _kind = k),
                ),
            ],
          ),
          ListTile(
            key: const Key('reminder-date'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(
              _date == null ? l10n.garageDueDate : m.formatMediumDate(_date!),
            ),
            onTap: () async {
              final now = DateTime.now();
              final d = await showDatePicker(
                context: context,
                initialDate: now.add(const Duration(days: 30)),
                firstDate: now,
                lastDate: DateTime(now.year + 5),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
          TextField(
            key: const Key('reminder-km'),
            controller: _km,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l10n.garageDueKm),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            key: const Key('reminder-save'),
            onPressed: _busy ? null : _save,
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
  }
}
