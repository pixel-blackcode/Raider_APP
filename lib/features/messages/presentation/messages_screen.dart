import 'package:flutter/material.dart';

import '../../../core/widgets/feature_placeholder_scaffold.dart';
import '../../../l10n/generated/app_localizations.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FeaturePlaceholderScaffold(
      title: l10n.messagesTitle,
      icon: Icons.chat_bubble_outline,
      emptyTitle: l10n.messagesEmptyTitle,
      emptyMessage: l10n.messagesEmptyBody,
    );
  }
}
