import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/backend_providers.dart';
import '../errors/app_exception.dart';

/// Buckets Storage (privés) et leurs limites, identiques à la migration SQL.
enum MediaBucket {
  avatars('avatars', 2 * 1024 * 1024),
  clubMedia('club-media', 5 * 1024 * 1024),
  postMedia('post-media', 5 * 1024 * 1024),
  listingMedia('listing-media', 5 * 1024 * 1024),
  rideMedia('ride-media', 5 * 1024 * 1024);

  const MediaBucket(this.id, this.maxBytes);

  final String id;
  final int maxBytes;
}

/// Image choisie par l'utilisateur, prête à être envoyée.
class PickedImage {
  const PickedImage({required this.bytes, required this.extension});

  final Uint8List bytes;

  /// Extension en minuscules, sans point (jpg, png, webp...).
  final String extension;

  static const _contentTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  String? get contentType => _contentTypes[extension.toLowerCase()];

  /// Vérifie le type et la taille avant envoi (le serveur les vérifie aussi).
  void validateFor(MediaBucket bucket) {
    if (contentType == null) {
      throw const AppException(AppException.unsupportedImage);
    }
    if (bytes.length > bucket.maxBytes) {
      throw const AppException(AppException.imageTooLarge);
    }
  }
}

/// Accès aux médias privés (photos de profil, logos et couvertures de club).
abstract interface class MediaRepository {
  /// Envoie l'image dans `<folder>/<baseName>-<horodatage>.<ext>` et
  /// retourne ce chemin. Un nom unique évite les images périmées en cache.
  Future<String> upload(
    MediaBucket bucket, {
    required String folder,
    required String baseName,
    required PickedImage image,
  });

  Future<void> remove(MediaBucket bucket, List<String> paths);

  /// Supprime tous les fichiers d'un dossier (ex. suppression de compte).
  Future<void> removeFolder(MediaBucket bucket, String folder);

  /// Image lisible avec la session courante ; `null` si [path] est vide.
  ImageProvider? imageProvider(MediaBucket bucket, String? path);
}

class SupabaseMediaRepository implements MediaRepository {
  SupabaseMediaRepository(
    this._client, {
    required this.baseUrl,
    required this.apiKey,
  });

  final SupabaseClient _client;
  final String baseUrl;
  final String apiKey;

  @override
  Future<String> upload(
    MediaBucket bucket, {
    required String folder,
    required String baseName,
    required PickedImage image,
  }) async {
    image.validateFor(bucket);
    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final path = '$folder/$baseName-$stamp.${image.extension.toLowerCase()}';
    try {
      await _client.storage
          .from(bucket.id)
          .uploadBinary(
            path,
            image.bytes,
            fileOptions: FileOptions(contentType: image.contentType),
          );
      return path;
    } catch (error) {
      throw AppException.from(error);
    }
  }

  @override
  Future<void> remove(MediaBucket bucket, List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _client.storage.from(bucket.id).remove(paths);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  @override
  Future<void> removeFolder(MediaBucket bucket, String folder) async {
    try {
      final files = await _client.storage.from(bucket.id).list(path: folder);
      await remove(bucket, [for (final f in files) '$folder/${f.name}']);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  @override
  ImageProvider? imageProvider(MediaBucket bucket, String? path) {
    if (path == null || path.isEmpty) return null;
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) return null;
    final encoded = path.split('/').map(Uri.encodeComponent).join('/');
    return NetworkImage(
      '$baseUrl/storage/v1/object/authenticated/${bucket.id}/$encoded',
      headers: {'Authorization': 'Bearer $token', 'apikey': apiKey},
    );
  }
}

final mediaRepositoryProvider = Provider<MediaRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  final config = ref.watch(appConfigProvider);
  return SupabaseMediaRepository(
    client,
    baseUrl: config.supabaseUrl,
    apiKey: config.supabasePublishableKey,
  );
});
