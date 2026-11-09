import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/media_repository.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/remote_avatar.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/club.dart';
import 'club_labels.dart';
import 'verified_badge.dart';

/// Carte de présentation d'un club dans une liste.
class ClubCard extends StatelessWidget {
  const ClubCard({super.key, required this.club, this.role, this.onTap});

  final Club club;
  final ClubRole? role;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ClubAvatar(club: club),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            club.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (club.isVerified) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const VerifiedBadge(compact: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      [
                        club.city,
                        club.visibility.label(l10n),
                        l10n.clubMemberCount(club.memberCount),
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (role != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        role!.label(l10n),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
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

/// Logo du club, ou son initiale à défaut.
class ClubAvatar extends ConsumerWidget {
  const ClubAvatar({super.key, required this.club, this.radius = 24});

  final Club club;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return RemoteAvatar(
      label: club.name,
      radius: radius,
      image: ref
          .watch(mediaRepositoryProvider)
          ?.imageProvider(MediaBucket.clubMedia, club.logoPath),
      backgroundColor: scheme.secondaryContainer,
      foregroundColor: scheme.onSecondaryContainer,
    );
  }
}
