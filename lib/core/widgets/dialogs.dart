import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Demande de confirmation. Retourne `true` si l'utilisateur confirme.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const Key('confirm-dialog-ok'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Saisie d'un texte court ; `null` si l'utilisateur annule.
Future<String?> showTextPrompt(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
  int maxLength = 500,
  String? prefix,
  String? initialValue,
  TextInputType? keyboardType,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TextPromptDialog(
      title: title,
      label: label,
      confirmLabel: confirmLabel,
      maxLength: maxLength,
      prefix: prefix,
      initialValue: initialValue,
      keyboardType: keyboardType,
    ),
  );
}

/// Boîte de saisie d'un texte court. Elle possède son contrôleur, libéré
/// seulement après l'animation de fermeture.
class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
    required this.maxLength,
    this.prefix,
    this.initialValue,
    this.keyboardType,
  });

  final String title;
  final String label;
  final String confirmLabel;
  final int maxLength;
  final String? prefix;
  final String? initialValue;
  final TextInputType? keyboardType;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('text-dialog-field'),
        controller: _controller,
        autofocus: true,
        maxLength: widget.maxLength,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixText: widget.prefix,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const Key('text-dialog-ok'),
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
