import 'package:flutter/material.dart';

import '../../../core/widgets/feature_placeholder_scaffold.dart';
import '../../../l10n/generated/app_localizations.dart';

class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FeaturePlaceholderScaffold(
      title: l10n.garageTitle,
      icon: Icons.two_wheeler,
      emptyTitle: l10n.garageEmptyTitle,
      emptyMessage: l10n.garageEmptyBody,
    );
  }
}
