import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/client_ref.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../community/presentation/community_ui.dart';
import '../data/marketplace_providers.dart';
import '../data/marketplace_repository.dart';
import '../domain/marketplace.dart';
import 'marketplace_labels.dart';

/// Photo de l'annonce : déjà en ligne (chemin) ou nouvellement choisie.
class _Photo {
  _Photo.remote(String this.path) : picked = null;
  _Photo.local(PickedImage this.picked) : path = null;

  String? path;
  final PickedImage? picked;
}

/// Créer ou modifier une annonce. Aucun paiement : prix indicatif.
class ListingFormScreen extends ConsumerStatefulWidget {
  const ListingFormScreen({super.key, this.listingId});

  final String? listingId;

  static const maxPhotos = 10;

  @override
  ConsumerState<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends ConsumerState<ListingFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _city = TextEditingController(text: 'Kinshasa');
  final _area = TextEditingController();
  ListingCategory _category = ListingCategory.parts;
  ListingCondition _condition = ListingCondition.good;
  Currency _currency = Currency.usd;
  final _photos = <_Photo>[];
  final _clientRef = newClientRef();
  bool _loading = false;
  bool _busy = false;
  String? _error;

  bool get _editing => widget.listingId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final l = await ref
        .read(marketplaceRepositoryProvider)
        ?.listing(widget.listingId!);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (l == null) return;
      _title.text = l.title;
      _description.text = l.description;
      _price.text = l.price == null
          ? ''
          : (l.price! == l.price!.truncateToDouble()
                ? l.price!.toStringAsFixed(0)
                : l.price!.toString());
      _city.text = l.city;
      _area.text = l.area ?? '';
      _category = l.category;
      _condition = l.condition;
      _currency = l.currency;
      _photos
        ..clear()
        ..addAll(l.mediaPaths.map(_Photo.remote));
    });
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _price, _city, _area]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addPhoto() async {
    try {
      final image = await ref
          .read(photoPickerProvider)
          .pick(maxDimension: 1600);
      if (image == null) return;
      image.validateFor(MediaBucket.listingMedia);
      setState(() => _photos.add(_Photo.local(image)));
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(marketplaceRepositoryProvider);
    final media = ref.read(mediaRepositoryProvider);
    final uid = ref.read(currentUserIdProvider);
    if (repo == null || uid == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final paths = <String>[];
      for (final p in _photos) {
        // Envoyée une seule fois, même après un échec.
        p.path ??= await media!.upload(
          MediaBucket.listingMedia,
          folder: uid,
          baseName: 'annonce',
          image: p.picked!,
        );
        paths.add(p.path!);
      }
      final draft = ListingDraft(
        category: _category,
        title: _title.text.trim(),
        description: _description.text.trim(),
        price: double.tryParse(_price.text.trim().replaceAll(',', '.')),
        currency: _currency,
        condition: _condition,
        city: _city.text.trim(),
        area: _area.text.trim().isEmpty ? null : _area.text.trim(),
      );
      String id;
      if (_editing) {
        id = widget.listingId!;
        final removed = await repo.update(id, draft, mediaPaths: paths);
        try {
          await media?.remove(MediaBucket.listingMedia, removed);
        } catch (_) {}
      } else {
        id = await repo.create(draft, clientRef: _clientRef, mediaPaths: paths);
      }
      ref
        ..invalidate(listingsProvider)
        ..invalidate(listingProvider(id));
      if (!mounted) return;
      showSnack(
        context,
        _editing ? l10n.listingSaved : l10n.listingPublishedDone,
      );
      if (_editing) {
        context.pop();
      } else {
        context.pushReplacement(AppRoutes.listing(id));
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error =
              '${l10n.listingNotSent} ${describeError(context, error)}',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<RiderColors>()!;
    final media = ref.watch(mediaRepositoryProvider);

    String? required(String? v, {int min = 2}) =>
        (v == null || v.trim().length < min)
        ? l10n.validationTooShort(min)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? l10n.listingEditTitle : l10n.listingNewTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Text(
                    l10n.listingPhotos(_photos.length),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final (i, p) in _photos.indexed)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox.square(
                                dimension: 88,
                                child: p.picked != null
                                    ? Image.memory(
                                        p.picked!.bytes,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            const Icon(Icons.image_outlined),
                                      )
                                    : (media?.imageProvider(
                                                MediaBucket.listingMedia,
                                                p.path,
                                              ) ==
                                              null
                                          ? const Icon(Icons.image_outlined)
                                          : Image(
                                              image: media!.imageProvider(
                                                MediaBucket.listingMedia,
                                                p.path,
                                              )!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  const Icon(
                                                    Icons.image_outlined,
                                                  ),
                                            )),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton.filledTonal(
                                key: Key('listing-photo-remove-$i'),
                                tooltip: l10n.actionDelete,
                                onPressed: _busy
                                    ? null
                                    : () => setState(() => _photos.removeAt(i)),
                                icon: const Icon(Icons.close, size: 18),
                              ),
                            ),
                          ],
                        ),
                      if (_photos.length < ListingFormScreen.maxPhotos)
                        SizedBox.square(
                          dimension: 88,
                          child: OutlinedButton(
                            key: const Key('listing-add-photo'),
                            onPressed: _busy ? null : _addPhoto,
                            child: const Icon(Icons.add_a_photo_outlined),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<ListingCategory>(
                    key: const Key('listing-category'),
                    initialValue: _category,
                    decoration: InputDecoration(
                      labelText: l10n.listingCategory,
                    ),
                    items: [
                      for (final c in ListingCategory.values)
                        DropdownMenuItem(value: c, child: Text(c.label(l10n))),
                    ],
                    onChanged: (v) =>
                        setState(() => _category = v ?? _category),
                  ),
                  TextFormField(
                    key: const Key('listing-title'),
                    controller: _title,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: l10n.listingTitleField,
                    ),
                    validator: (v) => required(v, min: 3),
                  ),
                  TextFormField(
                    key: const Key('listing-description'),
                    controller: _description,
                    maxLength: 3000,
                    minLines: 3,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: l10n.clubFieldDescription,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('listing-price-field'),
                          controller: _price,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.listingPriceField,
                            helperText: l10n.listingPriceHelper,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final n = double.tryParse(
                              v.trim().replaceAll(',', '.'),
                            );
                            return n == null || n < 0
                                ? l10n.listingPriceInvalid
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SegmentedButton<Currency>(
                        segments: const [
                          ButtonSegment(
                            value: Currency.usd,
                            label: Text('USD'),
                          ),
                          ButtonSegment(
                            value: Currency.cdf,
                            label: Text('CDF'),
                          ),
                        ],
                        selected: {_currency},
                        onSelectionChanged: (s) =>
                            setState(() => _currency = s.first),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<ListingCondition>(
                    key: const Key('listing-condition'),
                    initialValue: _condition,
                    decoration: InputDecoration(
                      labelText: l10n.listingCondition,
                    ),
                    items: [
                      for (final c in ListingCondition.values)
                        DropdownMenuItem(value: c, child: Text(c.label(l10n))),
                    ],
                    onChanged: (v) =>
                        setState(() => _condition = v ?? _condition),
                  ),
                  TextFormField(
                    key: const Key('listing-city'),
                    controller: _city,
                    maxLength: 80,
                    decoration: InputDecoration(labelText: l10n.listingCity),
                    validator: required,
                  ),
                  TextFormField(
                    key: const Key('listing-area'),
                    controller: _area,
                    maxLength: 80,
                    decoration: InputDecoration(
                      labelText: l10n.listingArea,
                      helperText: l10n.listingAreaHelper,
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        _error!,
                        key: const Key('listing-error'),
                        style: TextStyle(
                          color: colors.sos,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.listingNoPayment, style: theme.textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: AppSpacing.convoyTouchTarget,
                    child: FilledButton(
                      key: const Key('listing-submit'),
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const CircularProgressIndicator()
                          : Text(
                              _editing ? l10n.actionSave : l10n.listingPublish,
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
