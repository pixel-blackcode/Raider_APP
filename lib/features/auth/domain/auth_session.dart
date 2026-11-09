/// Session authentifiée, indépendante du SDK backend.
class AuthSession {
  const AuthSession({required this.userId, this.email});

  final String userId;
  final String? email;

  @override
  bool operator ==(Object other) =>
      other is AuthSession && other.userId == userId && other.email == email;

  @override
  int get hashCode => Object.hash(userId, email);
}

/// Résultat d'une inscription.
enum SignUpOutcome {
  /// Le compte est créé et la session ouverte.
  signedIn,

  /// Le compte est créé ; l'utilisateur doit confirmer son adresse e-mail.
  confirmationRequired,
}
