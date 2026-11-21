import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/router/app_router.dart';
import '../../features/auth/data/auth_providers.dart';
import '../backend/backend_providers.dart';

/// Accès au service de notifications du téléphone (Firebase Cloud
/// Messaging). Remplaçable en test.
abstract interface class PushMessaging {
  /// false si Firebase n'est pas configuré dans cette version (le reste de
  /// l'application fonctionne normalement, sans push).
  Future<bool> init();

  /// Demande l'autorisation d'afficher des notifications (Android 13+, iOS).
  Future<bool> requestPermission();

  Future<String?> token();

  Stream<String> get onTokenRefresh;

  /// Écran à ouvrir quand on touche une notification (application en
  /// arrière-plan).
  Stream<String> get onOpenRoute;

  /// Notification touchée alors que l'application était fermée.
  Future<String?> initialRoute();

  String get platform;
}

class FirebasePushMessaging implements PushMessaging {
  bool _ready = false;

  static const _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');

  static FirebaseOptions? _iosOptions() {
    if (defaultTargetPlatform != TargetPlatform.iOS || _iosAppId.isEmpty) {
      return null;
    }
    return const FirebaseOptions(
      apiKey: String.fromEnvironment('FIREBASE_IOS_API_KEY'),
      appId: _iosAppId,
      messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
      projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
      iosBundleId: 'com.ridergroup.riderGroup',
    );
  }

  @override
  Future<bool> init() async {
    if (kIsWeb) return false;
    try {
      if (Firebase.apps.isEmpty) {
        // Android : android/app/google-services.json (secret GitHub).
        // iOS : identifiants publics de l'app iOS Firebase fournis à la
        // compilation (--dart-define), sans fichier GoogleService-Info.plist.
        await Firebase.initializeApp(options: _iosOptions());
      }
      _ready = true;
    } catch (error) {
      debugPrint('[Push] Firebase non configuré : $error');
      _ready = false;
    }
    return _ready;
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final s = await FirebaseMessaging.instance.requestPermission();
    return s.authorizationStatus == AuthorizationStatus.authorized ||
        s.authorizationStatus == AuthorizationStatus.provisional;
  }

  // getToken/onTokenRefresh restent utilisés : le jeton d'enregistrement
  // classique est la cible documentée de l'API HTTP v1 (`message.token`)
  // utilisée par la fonction Edge send-push.
  @override
  // ignore: deprecated_member_use
  Future<String?> token() async =>
      // ignore: deprecated_member_use
      _ready ? FirebaseMessaging.instance.getToken() : null;

  @override
  Stream<String> get onTokenRefresh => _ready
      // ignore: deprecated_member_use
      ? FirebaseMessaging.instance.onTokenRefresh
      : const Stream.empty();

  @override
  Stream<String> get onOpenRoute => _ready
      ? FirebaseMessaging.onMessageOpenedApp
            .map((m) => m.data['route'] as String?)
            .where((r) => r != null && r.startsWith('/'))
            .cast<String>()
      : const Stream.empty();

  @override
  Future<String?> initialRoute() async {
    if (!_ready) return null;
    final m = await FirebaseMessaging.instance.getInitialMessage();
    final route = m?.data['route'] as String?;
    return route != null && route.startsWith('/') ? route : null;
  }

  @override
  String get platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
}

final pushMessagingProvider = Provider<PushMessaging>(
  (ref) => FirebasePushMessaging(),
);

/// Enregistre le téléphone auprès du serveur pour le compte connecté, le
/// désinscrit à la déconnexion, et ouvre l'écran d'une notification touchée.
class PushRegistrar {
  PushRegistrar(this._ref);

  final Ref _ref;
  String? _token;
  String? _registeredFor;
  final _subs = <StreamSubscription<Object?>>[];

  SupabaseClient? get _client => _ref.read(supabaseClientProvider);

  Future<void> start() async {
    final push = _ref.read(pushMessagingProvider);
    if (!await push.init()) return;
    _subs
      ..add(
        push.onTokenRefresh.listen((t) {
          _token = t;
          _registeredFor = null;
          _sync();
        }),
      )
      ..add(push.onOpenRoute.listen(_open));
    _ref.listen<String?>(currentUserIdProvider, (_, _) => _sync());
    final initial = await push.initialRoute();
    if (initial != null) {
      // Laisser le routeur et la session se mettre en place.
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(initial));
    }
    await _sync();
  }

  void _open(String route) {
    try {
      unawaited(_ref.read(routerProvider).push(route));
    } catch (_) {}
  }

  Future<void> _sync() async {
    final push = _ref.read(pushMessagingProvider);
    try {
      final user = _ref.read(currentUserIdProvider);
      final client = _client;
      if (client == null) return;
      if (user == null) {
        _registeredFor = null;
        return;
      }
      if (_registeredFor == user) return;
      await push.requestPermission();
      _token ??= await push.token();
      final token = _token;
      if (token == null) return;
      await client.rpc<void>(
        'register_push_token',
        params: {'p_token': token, 'p_platform': push.platform},
      );
      _registeredFor = user;
    } catch (error) {
      debugPrint('[Push] enregistrement impossible : $error');
    }
  }

  /// À appeler AVANT la déconnexion (le serveur exige la session).
  Future<void> unregister() async {
    final token = _token;
    if (token == null) return;
    try {
      final client = _client;
      if (client == null) return;
      await client.rpc<void>(
        'unregister_push_token',
        params: {'p_token': token},
      );
    } catch (_) {}
    _registeredFor = null;
  }

  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
  }
}

final pushRegistrarProvider = Provider<PushRegistrar>((ref) {
  final r = PushRegistrar(ref);
  ref.onDispose(r.dispose);
  return r;
});
