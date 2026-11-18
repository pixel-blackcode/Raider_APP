import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/data/auth_providers.dart';
import '../../clubs/domain/club.dart' show RiderVerificationForm;
import '../domain/profile.dart';

abstract interface class ProfileRepository {
  Future<Profile?> fetchProfile(String userId);

  Future<Profile?> findByUsername(String username);

  Future<Profile> updateProfile(String userId, ProfileUpdate update);

  /// Met à jour (ou retire avec `null`) la photo de profil.
  Future<void> setAvatarPath(String userId, String? path);

  Future<PrivacySettings> fetchPrivacySettings(String userId);

  Future<void> savePrivacySettings(String userId, PrivacySettings settings);

  /// Statut de la dernière demande de vérification (`pending`, `approved`,
  /// `rejected`) et la note de l'équipe ; `null` si aucune demande.
  Future<({String status, String? note})?> latestVerificationRequest(
    String userId,
  );

  /// Demande de vérification du motard (examinée par l'équipe, sans paiement).
  Future<void> requestVerification(RiderVerificationForm form);
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  static const _columns =
      'id, username, display_name, city, country_code, bio, avatar_path, '
      'verified_at, verified_until';

  @override
  Future<Profile?> fetchProfile(String userId) async {
    try {
      final row = await _client
          .from('profiles')
          .select(_columns)
          .eq('id', userId)
          .maybeSingle();
      return row == null ? null : Profile.fromJson(row);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  @override
  Future<Profile?> findByUsername(String username) async {
    try {
      final row = await _client
          .from('profiles')
          .select(_columns)
          .eq('username', username.trim().toLowerCase())
          .maybeSingle();
      return row == null ? null : Profile.fromJson(row);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  @override
  Future<Profile> updateProfile(String userId, ProfileUpdate update) async {
    try {
      final row = await _client
          .from('profiles')
          .update(update.toJson())
          .eq('id', userId)
          .select(_columns)
          .single();
      return Profile.fromJson(row);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  @override
  Future<void> setAvatarPath(String userId, String? path) async {
    try {
      await _client
          .from('profiles')
          .update({'avatar_path': path})
          .eq('id', userId);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  @override
  Future<PrivacySettings> fetchPrivacySettings(String userId) async {
    try {
      final row = await _client
          .from('profile_settings')
          .select(
            'discoverable, allow_club_invitations, allow_ride_invitations, '
            'avatar_visibility',
          )
          .eq('user_id', userId)
          .maybeSingle();
      return row == null
          ? const PrivacySettings()
          : PrivacySettings.fromJson(row);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  @override
  Future<void> savePrivacySettings(
    String userId,
    PrivacySettings settings,
  ) async {
    try {
      await _client.from('profile_settings').upsert({
        'user_id': userId,
        'discoverable': settings.discoverable,
        'allow_club_invitations': settings.allowClubInvitations,
        'allow_ride_invitations': settings.allowRideInvitations,
        'avatar_visibility': settings.avatarVisibility.name,
      });
    } catch (error) {
      throw AppException.from(error);
    }
  }

  @override
  Future<({String status, String? note})?> latestVerificationRequest(
    String userId,
  ) async {
    try {
      final row = await _client
          .from('rider_verification_requests')
          .select('status, review_note')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row == null
          ? null
          : (
              status: row['status'] as String,
              note: row['review_note'] as String?,
            );
    } catch (error) {
      throw AppException.from(error);
    }
  }

  @override
  Future<void> requestVerification(RiderVerificationForm form) async {
    try {
      await _client.rpc<Object?>(
        'request_rider_verification',
        params: {
          'p_real_name': form.realName,
          'p_contact_phone': form.contactPhone,
          'p_message': form.message,
          'p_document_paths': form.documentPaths,
        },
      );
    } catch (error) {
      throw AppException.from(error);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseProfileRepository(client);
});

/// Profil de l'utilisateur connecté.
final myProfileProvider = FutureProvider<Profile?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(profileRepositoryProvider);
  if (userId == null || repository == null) return null;
  return repository.fetchProfile(userId);
});

final privacySettingsProvider = FutureProvider.autoDispose<PrivacySettings>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(profileRepositoryProvider);
  if (userId == null || repository == null) return const PrivacySettings();
  return repository.fetchPrivacySettings(userId);
});

/// Dernière demande de vérification de l'utilisateur connecté.
final myRiderVerificationRequestProvider =
    FutureProvider.autoDispose<({String status, String? note})?>((ref) async {
      final userId = ref.watch(currentUserIdProvider);
      final repository = ref.watch(profileRepositoryProvider);
      if (userId == null || repository == null) return null;
      return repository.latestVerificationRequest(userId);
    });
