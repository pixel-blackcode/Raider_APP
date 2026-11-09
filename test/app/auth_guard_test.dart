import 'package:flutter_test/flutter_test.dart';
import 'package:rider_group/app/router/app_routes.dart';
import 'package:rider_group/app/router/auth_guard.dart';

String? redirect(String location, {bool ready = true, bool signedIn = false}) =>
    resolveAuthRedirect(
      location: Uri.parse(location),
      backendReady: ready,
      signedIn: signedIn,
    );

void main() {
  test('backend non configuré : aucune redirection', () {
    expect(redirect('/clubs', ready: false), isNull);
    expect(redirect(AppRoutes.signIn, ready: false), isNull);
  });

  test('déconnecté : redirection vers la connexion en mémorisant la page', () {
    expect(redirect(AppRoutes.home), AppRoutes.signIn);
    expect(redirect('/clubs/abc'), '/connexion?from=%2Fclubs%2Fabc');
    expect(redirect(AppRoutes.signIn), isNull);
    expect(redirect(AppRoutes.signUp), isNull);
  });

  test('connecté : les pages d\'authentification renvoient vers l\'app', () {
    expect(redirect(AppRoutes.signIn, signedIn: true), AppRoutes.home);
    expect(
      redirect('/connexion?from=%2Fclubs%2Fabc', signedIn: true),
      '/clubs/abc',
    );
    expect(redirect('/clubs', signedIn: true), isNull);
  });

  test('pas de redirection ouverte vers un site externe', () {
    for (final from in [
      'https://evil.example',
      '//evil.example',
      'evil',
      '/connexion',
    ]) {
      expect(
        redirect(
          Uri(
            path: AppRoutes.signIn,
            queryParameters: {'from': from},
          ).toString(),
          signedIn: true,
        ),
        AppRoutes.home,
        reason: from,
      );
    }
  });
}
