import 'package:flutter/material.dart';

/// Avatar circulaire : image distante si disponible, sinon initiale.
/// En cas d'échec de chargement, l'initiale reste affichée.
class RemoteAvatar extends StatelessWidget {
  const RemoteAvatar({
    super.key,
    required this.label,
    this.image,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final ImageProvider? image;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = label.trim().isEmpty
        ? '?'
        : label.trim().characters.first.toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? scheme.primaryContainer,
      foregroundImage: image,
      onForegroundImageError: image == null ? null : (_, _) {},
      child: Text(
        initial,
        style: TextStyle(
          color: foregroundColor ?? scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
