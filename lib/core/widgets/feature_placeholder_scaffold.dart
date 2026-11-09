import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'empty_state.dart';

/// Écran structurel d'une fonctionnalité pas encore livrée.
///
/// Affiche un état vide honnête (« Bientôt disponible ») plutôt que des
/// données fictives.
class FeaturePlaceholderScaffold extends StatelessWidget {
  const FeaturePlaceholderScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.emptyTitle,
    required this.emptyMessage,
    this.actions,
  });

  final String title;
  final IconData icon;
  final String emptyTitle;
  final String emptyMessage;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: EmptyState(
        icon: icon,
        title: emptyTitle,
        message: emptyMessage,
        badge: AppLocalizations.of(context).comingSoon,
      ),
    );
  }
}
