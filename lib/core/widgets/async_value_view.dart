import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../errors/error_messages.dart';
import 'empty_state.dart';

/// Affiche les trois états d'un [AsyncValue] : chargement, erreur, données.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) => data(value),
      AsyncError(:final error) => EmptyState(
        icon: Icons.cloud_off_outlined,
        title: AppLocalizations.of(context).errorTitle,
        message: describeError(context, error),
        action: onRetry == null
            ? null
            : OutlinedButton(
                onPressed: onRetry,
                child: Text(AppLocalizations.of(context).actionRetry),
              ),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
