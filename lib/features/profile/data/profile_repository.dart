import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/profile.dart';

abstract interface class ProfileRepository {
  Future<Profile?> fetchProfile(String userId);

  Future<Profile?> findByUsername(String username);

  Future<Profile> updateProfile(String userId, ProfileUpdate update);
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  static const _columns = 'id, username, display_name, city, country_code, bio';

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
