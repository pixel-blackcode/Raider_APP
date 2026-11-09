import 'package:flutter/material.dart';

import '../../../core/widgets/feature_placeholder_scaffold.dart';
import '../../../l10n/generated/app_localizations.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FeaturePlaceholderScaffold(
      title: l10n.marketplaceTitle,
      icon: Icons.storefront_outlined,
      emptyTitle: l10n.marketplaceEmptyTitle,
      emptyMessage: l10n.marketplaceEmptyBody,
    );
  }
}
