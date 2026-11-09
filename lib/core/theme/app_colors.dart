import 'package:flutter/material.dart';

/// Palette de marque Rider Group.
abstract final class AppColors {
  /// Orange « phare » : couleur principale de la marque.
  static const Color brand = Color(0xFFE8590C);

  /// Anthracite utilisé pour les surfaces sombres.
  static const Color asphalt = Color(0xFF1C1B1F);
}

/// Couleurs sémantiques propres au domaine (convoi, SOS, états GPS).
///
/// Accessibles via `Theme.of(context).extension<RiderColors>()!`.
@immutable
class RiderColors extends ThemeExtension<RiderColors> {
  const RiderColors({
    required this.sos,
    required this.onSos,
    required this.success,
    required this.warning,
    required this.stale,
  });

  static const light = RiderColors(
    sos: Color(0xFFC62828),
    onSos: Colors.white,
    success: Color(0xFF2E7D32),
    warning: Color(0xFFB26A00),
    stale: Color(0xFF757575),
  );

  static const dark = RiderColors(
    sos: Color(0xFFFF5449),
    onSos: Colors.black,
    success: Color(0xFF66BB6A),
    warning: Color(0xFFFFB74D),
    stale: Color(0xFF9E9E9E),
  );

  /// Alertes SOS et actions critiques.
  final Color sos;
  final Color onSos;

  /// Position à jour, alerte acquittée.
  final Color success;

  /// Retardataire potentiel, connexion dégradée.
  final Color warning;

  /// Position périmée.
  final Color stale;

  @override
  RiderColors copyWith({
    Color? sos,
    Color? onSos,
    Color? success,
    Color? warning,
    Color? stale,
  }) {
    return RiderColors(
      sos: sos ?? this.sos,
      onSos: onSos ?? this.onSos,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      stale: stale ?? this.stale,
    );
  }

  @override
  RiderColors lerp(RiderColors? other, double t) {
    if (other == null) return this;
    return RiderColors(
      sos: Color.lerp(sos, other.sos, t)!,
      onSos: Color.lerp(onSos, other.onSos, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      stale: Color.lerp(stale, other.stale, t)!,
    );
  }
}
