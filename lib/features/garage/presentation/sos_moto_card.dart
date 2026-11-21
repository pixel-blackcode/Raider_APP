import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/media_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/photo_viewer.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/garage_repository.dart';

/// La moto du motard en alerte (maquette 6) : modèle, couleur, plaque et
/// photo, pour le retrouver plus vite. Rien si la moto n'est pas partagée.
class SosMotoCard extends ConsumerWidget {
  const SosMotoCard({super.key, required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moto = ref.watch(sosMotorcycleProvider(alertId)).value;
    if (moto == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final photo = ref
        .watch(mediaRepositoryProvider)
        ?.imageProvider(MediaBucket.garageMedia, moto.photoPath);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        key: Key('sos-moto-$alertId'),
        children: [
          GestureDetector(
            onTap: photo == null
                ? null
                : () => openPhotoViewer(context, images: [photo]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 72,
                height: 72,
                color: AppColors.marine,
                child: photo == null
                    ? const Icon(
                        Icons.two_wheeler,
                        color: Colors.white54,
                        size: 36,
                      )
                    : Image(image: photo, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.garageSosHisMoto, style: theme.textTheme.labelSmall),
                Text(
                  '${moto.brand} ${moto.model}',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  [
                    if (moto.color != null) moto.color!,
                    if (moto.plate != null) moto.plate!,
                  ].join(' · '),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
