import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Badge « Vérifié », accordé uniquement par l'administration Rider Group.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = Theme.of(context).extension<RiderColors>()!.success;
    final icon = Icon(Icons.verified, color: color, size: compact ? 18 : 20);
    if (compact) {
      return Tooltip(
        message: l10n.clubVerified,
        child: Semantics(label: l10n.clubVerified, child: icon),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 4),
        Text(
          l10n.clubVerified,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
