import 'package:flutter/material.dart';

import '../../../core/widgets/feature_placeholder_scaffold.dart';
import '../../../l10n/generated/app_localizations.dart';

class RidesScreen extends StatelessWidget {
  const RidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FeaturePlaceholderScaffold(
      title: l10n.ridesTitle,
      icon: Icons.route,
      emptyTitle: l10n.ridesEmptyTitle,
      emptyMessage: l10n.ridesEmptyBody,
    );
  }
}
