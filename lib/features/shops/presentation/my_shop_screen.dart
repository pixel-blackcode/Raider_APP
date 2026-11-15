import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/remote_avatar.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../community/presentation/community_ui.dart';
import '../../profile/data/profile_repository.dart';
import '../data/shops_repository.dart';
import '../domain/shop.dart';

/// Ouvrir ou modifier sa boutique (motards vérifiés, gratuit).
class MyShopScreen extends ConsumerWidget {
  const MyShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(myProfileProvider);
    final shop = ref.watch(myShopProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shopMine)),
      body: AsyncValueView(
        value: profile,
        data: (p) {
          if (p == null) return const SizedBox.shrink();
          if (!p.isVerified && shop.value == null) {
            return EmptyState(
              icon: Icons.verified_outlined,
              title: l10n.shopVerifiedOnlyTitle,
              message: l10n.shopVerifiedOnlyBody,
              action: FilledButton(
                key: const Key('shop-get-verified'),
                onPressed: () => context.push(AppRoutes.riderVerification),
                child: Text(l10n.riderVerificationCta),
              ),
            );
          }
          return AsyncValueView(
            value: shop,
            data: (s) => _ShopForm(shop: s),
          );
        },
      ),
    );
  }
}

class _ShopForm extends ConsumerStatefulWidget {
  const _ShopForm({this.shop});

  final Shop? shop;

  @override
  ConsumerState<_ShopForm> createState() => _ShopFormState();
}

class _ShopFormState extends ConsumerState<_ShopForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.shop?.name);
  late final _city = TextEditingController(
    text: widget.shop?.city ?? 'Kinshasa',
  );
  late final _area = TextEditingController(text: widget.shop?.area);
  late final _phone = TextEditingController(text: widget.shop?.phone ?? '+243');
  late final _description = TextEditingController(
    text: widget.shop?.description,
  );
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _city, _area, _phone, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.refreshShops();
    } catch (error) {
      if (mounted) showSnack(context, describeError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final phone = _phone.text.replaceAll(RegExp(r'[\s.\-()]'), '');
    await _run(() async {
      final id = await ref
          .read(shopsRepositoryProvider)!
          .saveMine(
            ShopDraft(
              name: _name.text,
              city: _city.text,
              area: _area.text,
              description: _description.text,
              phone: phone == '+243' || phone.isEmpty ? null : phone,
            ),
          );
      if (!mounted) return;
      showSnack(context, l10n.shopSaved);
      context.pushReplacement(AppRoutes.shop(id));
    });
  }

  Future<void> _logo() async {
    final image = await ref.read(photoPickerProvider).pick(maxDimension: 800);
    if (image == null) return;
    final me = ref.read(currentUserIdProvider)!;
    await _run(() async {
      final media = ref.read(mediaRepositoryProvider)!;
      final path = await media.upload(
        MediaBucket.shopMedia,
        folder: me,
        baseName: 'logo',
        image: image,
      );
      final old = await ref.read(shopsRepositoryProvider)!.setMyLogo(path);
      if (old != null && old != path) {
        await media.remove(MediaBucket.shopMedia, [old]);
      }
    });
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.shopDeleteTitle,
      message: l10n.shopDeleteBody,
      confirmLabel: l10n.actionDelete,
    );
    if (!ok) return;
    await _run(() async {
      await ref.read(shopsRepositoryProvider)!.deleteMine();
      if (mounted) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = widget.shop;
    final media = ref.watch(mediaRepositoryProvider);
    String? len(String? v, int min, int max) {
      final n = (v ?? '').trim().length;
      return n < min || n > max ? l10n.validationTooShort(min) : null;
    }

    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(l10n.shopIntro),
          const SizedBox(height: AppSpacing.md),
          if (s != null)
            Center(
              child: InkWell(
                key: const Key('shop-logo'),
                onTap: _busy ? null : _logo,
                child: Column(
                  children: [
                    RemoteAvatar(
                      label: s.name,
                      radius: 40,
                      image: media?.imageProvider(
                        MediaBucket.shopMedia,
                        s.logoPath,
                      ),
                    ),
                    Text(l10n.shopLogo),
                  ],
                ),
              ),
            ),
          TextFormField(
            key: const Key('shop-field-name'),
            controller: _name,
            maxLength: 80,
            decoration: InputDecoration(labelText: l10n.shopFieldName),
            validator: (v) => len(v, 3, 80),
          ),
          TextFormField(
            key: const Key('shop-field-city'),
            controller: _city,
            maxLength: 80,
            decoration: InputDecoration(labelText: l10n.eventFieldCity),
            validator: (v) => len(v, 2, 80),
          ),
          TextFormField(
            controller: _area,
            maxLength: 80,
            decoration: InputDecoration(labelText: l10n.shopFieldArea),
          ),
          TextFormField(
            key: const Key('shop-field-phone'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.shopFieldPhone,
              helperText: l10n.shopFieldPhoneHelp,
            ),
            validator: (v) {
              final p = (v ?? '').replaceAll(RegExp(r'[\s.\-()]'), '');
              if (p.isEmpty || p == '+243') return null;
              return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(p)
                  ? null
                  : l10n.verificationPhoneInvalid;
            },
          ),
          TextFormField(
            controller: _description,
            maxLength: 2000,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(labelText: l10n.eventFieldDescription),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            key: const Key('shop-save'),
            onPressed: _busy ? null : _save,
            child: Text(s == null ? l10n.shopOpen : l10n.actionSave),
          ),
          if (s != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              key: const Key('shop-delete'),
              onPressed: _busy ? null : _delete,
              child: Text(l10n.shopDelete),
            ),
          ],
        ],
      ),
    );
  }
}
