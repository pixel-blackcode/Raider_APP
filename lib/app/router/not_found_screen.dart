import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../l10n/generated/app_localizations.dart';
import 'app_routes.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notFoundTitle)),
      body: EmptyState(
        icon: Icons.wrong_location_outlined,
        title: l10n.notFoundTitle,
        message: l10n.notFoundBody,
        action: FilledButton(
          onPressed: () => context.go(AppRoutes.home),
          child: Text(l10n.backToHome),
        ),
      ),
    );
  }
}
