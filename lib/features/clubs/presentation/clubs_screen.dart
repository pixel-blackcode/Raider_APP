import 'package:flutter/material.dart';

import '../../../core/widgets/feature_placeholder_scaffold.dart';
import '../../../l10n/generated/app_localizations.dart';

class ClubsScreen extends StatelessWidget {
  const ClubsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FeaturePlaceholderScaffold(
      title: l10n.clubsTitle,
      icon: Icons.groups,
      emptyTitle: l10n.clubsEmptyTitle,
      emptyMessage: l10n.clubsEmptyBody,
    );
  }
}
