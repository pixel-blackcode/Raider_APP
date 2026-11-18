import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/preferences_providers.dart';

/// Fonds proposés pour une conversation. Le choix est propre à chaque
/// conversation et reste sur ce téléphone (les autres membres gardent le
/// leur).
enum ChatWallpaperPreset {
  none,
  asphalt,
  sunset,
  night,
  road,
  savanna;

  Decoration? decoration() => switch (this) {
    none => null,
    asphalt => const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2B2A30), Color(0xFF141317)],
      ),
    ),
    sunset => const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFD8B5), Color(0xFFFF9A5C), Color(0xFFE8590C)],
      ),
    ),
    night => const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF14213D), Color(0xFF0B1224)],
      ),
    ),
    road => const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF3A3A3A),
          Color(0xFF3A3A3A),
          Color(0xFFFCA311),
          Color(0xFFFCA311),
          Color(0xFF3A3A3A),
        ],
        stops: [0, 0.46, 0.46, 0.54, 0.54],
        tileMode: TileMode.repeated,
      ),
    ),
    savanna => const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF4DF), Color(0xFFE9D3A8)],
      ),
    ),
  };
}

/// Fond choisi : un modèle, ou une photo de la galerie.
sealed class ChatWallpaper {
  const ChatWallpaper();
}

class PresetWallpaper extends ChatWallpaper {
  const PresetWallpaper(this.preset);

  final ChatWallpaperPreset preset;
}

class PhotoWallpaper extends ChatWallpaper {
  const PhotoWallpaper(this.bytes);

  final Uint8List bytes;
}

class ChatWallpaperController extends Notifier<Map<String, ChatWallpaper>> {
  static String keyFor(String conversationId) =>
      'chat.wallpaper.$conversationId';

  @override
  Map<String, ChatWallpaper> build() => {};

  /// Lecture sans modifier l'état (appelable pendant la construction).
  ChatWallpaper of(String conversationId) =>
      state[conversationId] ??
      _decoded.putIfAbsent(
        conversationId,
        () => _decode(
          ref.read(sharedPreferencesProvider).getString(keyFor(conversationId)),
        ),
      );

  final _decoded = <String, ChatWallpaper>{};

  Future<void> set(String conversationId, ChatWallpaper value) async {
    state = {...state, conversationId: value};
    final prefs = ref.read(sharedPreferencesProvider);
    final key = keyFor(conversationId);
    switch (value) {
      case PresetWallpaper(preset: ChatWallpaperPreset.none):
        await prefs.remove(key);
      case PresetWallpaper(:final preset):
        await prefs.setString(key, 'preset:${preset.name}');
      case PhotoWallpaper(:final bytes):
        await prefs.setString(key, 'photo:${base64Encode(bytes)}');
    }
  }

  static ChatWallpaper _decode(String? raw) {
    if (raw == null) return const PresetWallpaper(ChatWallpaperPreset.none);
    if (raw.startsWith('photo:')) {
      try {
        return PhotoWallpaper(base64Decode(raw.substring(6)));
      } catch (_) {
        return const PresetWallpaper(ChatWallpaperPreset.none);
      }
    }
    final name = raw.replaceFirst('preset:', '');
    return PresetWallpaper(
      ChatWallpaperPreset.values.firstWhere(
        (p) => p.name == name,
        orElse: () => ChatWallpaperPreset.none,
      ),
    );
  }
}

final chatWallpaperProvider =
    NotifierProvider<ChatWallpaperController, Map<String, ChatWallpaper>>(
      ChatWallpaperController.new,
    );

/// Fond d'une conversation, prêt à afficher derrière les messages.
class ChatWallpaperBackground extends ConsumerWidget {
  const ChatWallpaperBackground({
    super.key,
    required this.conversationId,
    required this.child,
  });

  final String conversationId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(chatWallpaperProvider);
    final w = ref.read(chatWallpaperProvider.notifier).of(conversationId);
    final decoration = switch (w) {
      PresetWallpaper(:final preset) => preset.decoration(),
      PhotoWallpaper(:final bytes) => BoxDecoration(
        image: DecorationImage(
          image: MemoryImage(bytes),
          fit: BoxFit.cover,
          // Voile pour garder les bulles lisibles.
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.25),
            BlendMode.darken,
          ),
        ),
      ),
    };
    if (decoration == null) return child;
    return DecoratedBox(
      key: const Key('chat-wallpaper'),
      decoration: decoration,
      child: child,
    );
  }
}
