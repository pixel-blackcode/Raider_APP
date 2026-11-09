import 'app_routes.dart';

/// Décide d'une éventuelle redirection selon l'état d'authentification.
///
/// - Backend non configuré : aucune authentification possible, l'application
///   reste consultable en mode dégradé (les écrans l'indiquent).
/// - Backend prêt, utilisateur déconnecté : seules les pages de connexion et
///   d'inscription sont accessibles.
/// - Utilisateur connecté : les pages de connexion renvoient à l'accueil.
String? resolveAuthRedirect({
  required Uri location,
  required bool backendReady,
  required bool signedIn,
}) {
  final path = location.path;
  final onAuthPage = AppRoutes.authPages.contains(path);

  if (!backendReady) return null;

  if (!signedIn) {
    if (onAuthPage) return null;
    final from = location.toString();
    return Uri(
      path: AppRoutes.signIn,
      queryParameters: path == AppRoutes.home || path == '/'
          ? null
          : {'from': from},
    ).toString();
  }

  if (onAuthPage) {
    final from = location.queryParameters['from'];
    return _isSafeInternalPath(from) ? from : AppRoutes.home;
  }
  return null;
}

/// N'autorise que les chemins internes (évite les redirections ouvertes).
bool _isSafeInternalPath(String? value) {
  if (value == null || value.isEmpty) return false;
  final uri = Uri.tryParse(value);
  return uri != null &&
      !uri.hasScheme &&
      !uri.hasAuthority &&
      value.startsWith('/') &&
      !value.startsWith('//') &&
      !AppRoutes.authPages.contains(uri.path);
}
