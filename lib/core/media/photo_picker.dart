import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'media_repository.dart';

/// Sélection d'une photo dans la galerie de l'appareil.
abstract interface class PhotoPicker {
  /// `null` si l'utilisateur annule. L'image est redimensionnée et
  /// recompressée par la plateforme pour limiter les données mobiles.
  Future<PickedImage?> pick({required double maxDimension});
}

class DevicePhotoPicker implements PhotoPicker {
  DevicePhotoPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedImage?> pick({required double maxDimension}) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxDimension,
      maxHeight: maxDimension,
      imageQuality: 85,
    );
    if (file == null) return null;
    final name = file.name.toLowerCase();
    final dot = name.lastIndexOf('.');
    return PickedImage(
      bytes: await file.readAsBytes(),
      extension: dot < 0 ? '' : name.substring(dot + 1),
    );
  }
}

final photoPickerProvider = Provider<PhotoPicker>((ref) => DevicePhotoPicker());
