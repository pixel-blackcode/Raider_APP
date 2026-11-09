/// Configuration de l'application, injectée à la compilation.
///
/// Les valeurs proviennent de `--dart-define` ou `--dart-define-from-file`
/// (voir `env/example.json` et `docs/CONFIGURATION.md`). Aucune valeur
/// sensible n'est codée en dur dans le dépôt.
///
/// Seule la clé *publishable* (anciennement « anon ») de Supabase peut être
/// fournie au client : elle est conçue pour être publique et la sécurité des
/// données repose sur les politiques Row Level Security côté serveur.
/// La clé `service_role` / *secret* ne doit JAMAIS être fournie ici.
library;

import 'dart:convert';

enum AppEnvironment {
  development('dev'),
  staging('staging'),
  production('prod');

  const AppEnvironment(this.code);

  final String code;

  static AppEnvironment parse(String raw) {
    final value = raw.trim().toLowerCase();
    for (final env in AppEnvironment.values) {
      if (env.code == value || env.name == value) return env;
    }
    return AppEnvironment.development;
  }
}

/// Problèmes de configuration détectés au démarrage.
enum ConfigIssue {
  missingSupabaseUrl,
  invalidSupabaseUrl,
  insecureSupabaseUrl,
  missingSupabaseKey,
  forbiddenSecretKey,
}

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  /// Lit la configuration fournie à la compilation.
  factory AppConfig.fromEnvironment() {
    return AppConfig.fromMap(const {
      'APP_ENV': String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
      'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
      'SUPABASE_PUBLISHABLE_KEY': String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
      ),
    });
  }

  /// Construit la configuration à partir d'une table clé/valeur (tests).
  factory AppConfig.fromMap(Map<String, String> values) {
    return AppConfig(
      environment: AppEnvironment.parse(values['APP_ENV'] ?? 'dev'),
      supabaseUrl: (values['SUPABASE_URL'] ?? '').trim(),
      supabasePublishableKey: (values['SUPABASE_PUBLISHABLE_KEY'] ?? '').trim(),
    );
  }

  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabasePublishableKey;

  /// Liste des problèmes empêchant l'initialisation du backend.
  List<ConfigIssue> get issues {
    final result = <ConfigIssue>[];

    if (supabaseUrl.isEmpty) {
      result.add(ConfigIssue.missingSupabaseUrl);
    } else {
      final uri = Uri.tryParse(supabaseUrl);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        result.add(ConfigIssue.invalidSupabaseUrl);
      } else if (uri.scheme != 'https' && !_isLocalHost(uri)) {
        // HTTP n'est toléré que pour une instance Supabase locale.
        result.add(ConfigIssue.insecureSupabaseUrl);
      }
    }

    if (supabasePublishableKey.isEmpty) {
      result.add(ConfigIssue.missingSupabaseKey);
    } else if (looksLikeSecretKey(supabasePublishableKey)) {
      result.add(ConfigIssue.forbiddenSecretKey);
    }

    return result;
  }

  bool get isBackendConfigured => issues.isEmpty;

  static bool _isLocalHost(Uri uri) {
    const localHosts = {'localhost', '127.0.0.1', '10.0.2.2'};
    return uri.scheme == 'http' && localHosts.contains(uri.host);
  }

  /// Détecte une clé serveur fournie par erreur au client.
  ///
  /// - Nouvelles clés Supabase : préfixe `sb_secret_`.
  /// - Anciennes clés JWT : rôle `service_role` dans la charge utile.
  static bool looksLikeSecretKey(String key) {
    if (key.startsWith('sb_secret_')) return true;
    final parts = key.split('.');
    if (parts.length != 3) return false;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      return payload.contains('"service_role"');
    } on FormatException {
      return false;
    }
  }
}
