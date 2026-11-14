import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/preferences_providers.dart';

/// Sons de l'application (son système du téléphone), remplaçables en test.
abstract interface class AlertSound {
  /// Nouvelle notification ou nouveau message.
  Future<void> notification();

  /// Alerte SOS (plus marquée).
  Future<void> alert();

  /// Coupe le son en cours.
  Future<void> stop();
}

class RingtoneAlertSound implements AlertSound {
  final _player = FlutterRingtonePlayer();

  @override
  Future<void> notification() async {
    try {
      await _player.playNotification();
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  @override
  Future<void> alert() async {
    try {
      await _player.playAlarm(looping: false, asAlarm: false, volume: 1);
    } catch (_) {
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }
}

final alertSoundProvider = Provider<AlertSound>((ref) => RingtoneAlertSound());

/// Sons activés ? (réglage local, activé par défaut). Le SOS sonne toujours.
class SoundsEnabledController extends Notifier<bool> {
  static const storageKey = 'settings.sounds_enabled';

  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(storageKey) ?? true;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(storageKey, value);
  }
}

final soundsEnabledProvider = NotifierProvider<SoundsEnabledController, bool>(
  SoundsEnabledController.new,
);
