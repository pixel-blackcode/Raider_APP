import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/widgets/feature_placeholder_scaffold.dart';
import '../../../l10n/generated/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FeaturePlaceholderScaffold(
      title: l10n.profileTitle,
      icon: Icons.person_outline,
      emptyTitle: l10n.profileSignedOutTitle,
      emptyMessage: l10n.profileSignedOutBody,
      actions: [
        IconButton(
          tooltip: l10n.settingsTitle,
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push(AppRoutes.settings),
        ),
      ],
    );
  }
}
