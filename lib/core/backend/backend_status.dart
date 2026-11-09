import '../config/app_config.dart';

/// État de l'initialisation du backend Supabase.
///
/// L'application ne prétend jamais être connectée : [BackendReady] signifie
/// uniquement que le client Supabase a été initialisé avec une configuration
/// valide. La joignabilité réelle du serveur est vérifiée par les requêtes.
sealed class BackendStatus {
  const BackendStatus();

  bool get isReady => this is BackendReady;
}

/// Aucun identifiant Supabase valide n'a été fourni à la compilation.
final class BackendNotConfigured extends BackendStatus {
  const BackendNotConfigured(this.issues);

  final List<ConfigIssue> issues;
}

/// Le client Supabase est initialisé.
final class BackendReady extends BackendStatus {
  const BackendReady(this.environment);

  final AppEnvironment environment;
}

/// L'initialisation du client a échoué.
final class BackendFailed extends BackendStatus {
  const BackendFailed(this.error);

  final Object error;
}
