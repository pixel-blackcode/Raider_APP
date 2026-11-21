import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../community/presentation/community_ui.dart';
import '../data/garage_repository.dart';
import '../domain/garage.dart';

/// Ajouter ou modifier une moto (maquette 2).
class MotoFormScreen extends ConsumerWidget {
  const MotoFormScreen({super.key, this.motoId});

  final String? motoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final moto = motoId == null
        ? null
        : ref
              .watch(motorcyclesProvider)
              .value
              ?.where((m) => m.id == motoId)
              .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(motoId == null ? l10n.garageAddMoto : l10n.garageEditMoto),
      ),
      body: motoId != null && moto == null
          ? const Center(child: CircularProgressIndicator())
          : _MotoForm(moto: moto),
    );
  }
}

class _MotoForm extends ConsumerStatefulWidget {
  const _MotoForm({this.moto});

  final Motorcycle? moto;

  @override
  ConsumerState<_MotoForm> createState() => _MotoFormState();
}

class _MotoFormState extends ConsumerState<_MotoForm> {
  final _form = GlobalKey<FormState>();
  late final _brand = TextEditingController(text: widget.moto?.brand);
  late final _model = TextEditingController(text: widget.moto?.model);
  late final _year = TextEditingController(text: widget.moto?.year?.toString());
  late final _cc = TextEditingController(text: widget.moto?.cc?.toString());
  late final _color = TextEditingController(text: widget.moto?.color);
  late final _plate = TextEditingController(text: widget.moto?.plate);
  late final _km = TextEditingController(
    text: widget.moto == null ? '' : '${widget.moto!.odometerKm}',
  );
  late bool _primary = widget.moto?.isPrimary ?? false;
  late bool _sos = widget.moto?.showInSos ?? true;
  PickedImage? _photo;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_brand, _model, _year, _cc, _color, _plate, _km]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final image = await ref
          .read(photoPickerProvider)
          .pick(maxDimension: 1600);
      if (image == null) return;
      image.validateFor(MediaBucket.garageMedia);
      setState(() => _photo = image);
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    }
  }

  int? _int(TextEditingController c) =>
      int.tryParse(c.text.replaceAll(RegExp(r'[\s .]'), ''));

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(garageRepositoryProvider)!;
    setState(() => _busy = true);
    try {
      final id = await repo.saveMotorcycle(
        widget.moto?.id,
        MotorcycleDraft(
          brand: _brand.text,
          model: _model.text,
          year: _int(_year),
          cc: _int(_cc),
          color: _color.text.trim().isEmpty ? null : _color.text.trim(),
          plate: _plate.text.trim().isEmpty ? null : _plate.text.trim(),
          odometerKm: _int(_km) ?? 0,
          isPrimary: _primary,
          showInSos: _sos,
        ),
      );
      final photo = _photo;
      if (photo != null) {
        final media = ref.read(mediaRepositoryProvider)!;
        final path = await media.upload(
          MediaBucket.garageMedia,
          folder: ref.read(currentUserIdProvider)!,
          baseName: 'moto',
          image: photo,
        );
        final old = await repo.setPhoto(id, path);
        if (old != null && old != path) {
          await media.remove(MediaBucket.garageMedia, [old]);
        }
      }
      ref.refreshGarage(id);
      if (!mounted) return;
      if (widget.moto == null) {
        context.pushReplacement(AppRoutes.motorcycle(id));
      } else {
        context.pop();
      }
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
    final existing = widget.moto?.photoPath;
    final media = ref.watch(mediaRepositoryProvider);
    final ImageProvider? preview = _photo == null
        ? media?.imageProvider(MediaBucket.garageMedia, existing)
        : MemoryImage(_photo!.bytes);
    final digits = [FilteringTextInputFormatter.digitsOnly];
    String? required(String? v) =>
        (v ?? '').trim().isEmpty ? l10n.validationTooShort(1) : null;

    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Material(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const Key('moto-photo'),
              onTap: _busy ? null : _pickPhoto,
              child: SizedBox(
                height: 140,
                child: preview == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 32,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.garageAddPhoto,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : Image(image: preview, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('moto-brand'),
                  controller: _brand,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.garageBrand),
                  validator: required,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextFormField(
                  key: const Key('moto-model'),
                  controller: _model,
                  maxLength: 60,
                  decoration: InputDecoration(labelText: l10n.garageModel),
                  validator: required,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _year,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                  maxLength: 4,
                  decoration: InputDecoration(labelText: l10n.garageYear),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextFormField(
                  controller: _cc,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                  maxLength: 4,
                  decoration: InputDecoration(labelText: l10n.garageCc),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _color,
                  maxLength: 40,
                  decoration: InputDecoration(labelText: l10n.garageColor),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextFormField(
                  key: const Key('moto-plate'),
                  controller: _plate,
                  maxLength: 20,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(labelText: l10n.garagePlate),
                ),
              ),
            ],
          ),
          TextFormField(
            key: const Key('moto-km'),
            controller: _km,
            keyboardType: TextInputType.number,
            inputFormatters: digits,
            maxLength: 7,
            decoration: InputDecoration(labelText: l10n.garageOdometer),
          ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  key: const Key('moto-primary'),
                  value: _primary,
                  onChanged: (v) => setState(() => _primary = v),
                  title: Text(l10n.garagePrimary),
                  subtitle: Text(l10n.garagePrimaryHelp),
                ),
                SwitchListTile(
                  key: const Key('moto-sos'),
                  value: _sos,
                  onChanged: (v) => setState(() => _sos = v),
                  title: Text(l10n.garageShowInSos),
                  subtitle: Text(l10n.garageShowInSosHelp),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.garagePrivacyNote, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            key: const Key('moto-save'),
            onPressed: _busy ? null : _save,
            child: Text(l10n.garageSaveMoto),
          ),
        ],
      ),
    );
  }
}
