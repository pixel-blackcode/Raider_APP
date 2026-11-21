import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_messages.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../community/presentation/community_ui.dart';
import '../data/garage_repository.dart';
import '../domain/garage.dart';
import 'garage_labels.dart';

/// Nouvel entretien (maquette 4).
class MaintenanceFormScreen extends ConsumerStatefulWidget {
  const MaintenanceFormScreen({super.key, required this.motoId});

  final String motoId;

  @override
  ConsumerState<MaintenanceFormScreen> createState() =>
      _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends ConsumerState<MaintenanceFormScreen> {
  MaintenanceKind _kind = MaintenanceKind.oil;
  DateTime _date = DateTime.now();
  final _km = TextEditingController();
  final _cost = TextEditingController();
  final _garage = TextEditingController();
  final _note = TextEditingController();
  GarageCurrency _currency = GarageCurrency.usd;
  bool _remind = true;
  PickedImage? _invoice;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_km, _cost, _garage, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 30),
      lastDate: now,
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickInvoice() async {
    try {
      final image = await ref
          .read(photoPickerProvider)
          .pick(maxDimension: 2000);
      if (image == null) return;
      image.validateFor(MediaBucket.garageMedia);
      setState(() => _invoice = image);
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    }
  }

  Future<void> _save() async {
    final km = int.tryParse(_km.text.replaceAll(RegExp(r'\s'), ''));
    final cost = double.tryParse(
      _cost.text.replaceAll(',', '.').replaceAll(' ', ''),
    );
    setState(() => _busy = true);
    try {
      String? invoicePath;
      final invoice = _invoice;
      if (invoice != null) {
        invoicePath = await ref
            .read(mediaRepositoryProvider)!
            .upload(
              MediaBucket.garageMedia,
              folder: ref.read(currentUserIdProvider)!,
              baseName: 'facture',
              image: invoice,
            );
      }
      await ref
          .read(garageRepositoryProvider)!
          .addMaintenance(
            widget.motoId,
            MaintenanceDraft(
              kind: _kind,
              doneOn: _date,
              odometerKm: km,
              cost: cost,
              currency: _currency,
              garage: _garage.text.trim().isEmpty ? null : _garage.text.trim(),
              note: _note.text.trim().isEmpty ? null : _note.text.trim(),
              invoicePath: invoicePath,
              remindNext: _remind,
            ),
          );
      ref.refreshGarage(widget.motoId);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final moto = ref
        .watch(motorcyclesProvider)
        .value
        ?.where((m) => m.id == widget.motoId)
        .firstOrNull;
    final canRemind = const {
      MaintenanceKind.oil,
      MaintenanceKind.chain,
      MaintenanceKind.tires,
      MaintenanceKind.brakes,
      MaintenanceKind.service,
      MaintenanceKind.battery,
    }.contains(_kind);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.garageNewMaintenance),
        bottom: moto == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(20),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(moto.name, style: theme.textTheme.bodySmall),
                ),
              ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(l10n.garageMaintenanceType, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final k in MaintenanceKind.forRecords)
                ChoiceChip(
                  key: Key('kind-${k.name}'),
                  label: Text(k.label(l10n)),
                  selected: _kind == k,
                  onSelected: (_) => setState(() => _kind = k),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(l10n.garageDate),
            subtitle: Text(
              MaterialLocalizations.of(context).formatMediumDate(_date),
            ),
            onTap: _pickDate,
          ),
          TextField(
            key: const Key('maintenance-km'),
            controller: _km,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.garageOdometer,
              helperText: moto == null
                  ? null
                  : l10n.garageCurrentKm(formatKm(moto.odometerKm)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('maintenance-cost'),
                  controller: _cost,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: l10n.garageCost),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SegmentedButton<GarageCurrency>(
                segments: const [
                  ButtonSegment(value: GarageCurrency.usd, label: Text('USD')),
                  ButtonSegment(value: GarageCurrency.cdf, label: Text('CDF')),
                ],
                selected: {_currency},
                onSelectionChanged: (s) => setState(() => _currency = s.first),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _garage,
            maxLength: 80,
            decoration: InputDecoration(labelText: l10n.garageGarage),
          ),
          TextField(
            controller: _note,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(labelText: l10n.garageNote),
          ),
          Card(
            child: Column(
              children: [
                if (canRemind)
                  SwitchListTile(
                    key: const Key('maintenance-remind'),
                    value: _remind,
                    onChanged: (v) => setState(() => _remind = v),
                    title: Text(l10n.garageRemindNext(_kind.label(l10n))),
                    subtitle: Text(l10n.garageRemindNextHelp),
                  ),
                ListTile(
                  leading: Icon(
                    _invoice == null
                        ? Icons.receipt_long_outlined
                        : Icons.check_circle,
                  ),
                  title: Text(
                    _invoice == null
                        ? l10n.garageAddInvoice
                        : l10n.garageInvoiceAdded,
                  ),
                  onTap: _busy ? null : _pickInvoice,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            key: const Key('maintenance-save'),
            onPressed: _busy ? null : _save,
            child: Text(l10n.garageSaveMaintenance),
          ),
        ],
      ),
    );
  }
}
