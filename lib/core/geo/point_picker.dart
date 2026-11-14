import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../features/convoy/data/location_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../config/app_config.dart';

class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;
}

/// Ouvre un sélecteur de point sur carte ; null si annulé. Remplaçable en
/// test (pas de rendu natif MapLibre en test de widget).
typedef PointPicker = Future<GeoPoint?> Function(
  BuildContext context, {
  GeoPoint? initial,
  required String title,
});

final pointPickerProvider = Provider<PointPicker>(
  (ref) =>
      (context, {initial, required title}) =>
          Navigator.of(context, rootNavigator: true).push<GeoPoint>(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) =>
                  MapPointPickerScreen(initial: initial, title: title),
            ),
          ),
);

/// Carte plein écran : on déplace la carte sous le viseur central, puis
/// « Valider ce point ».
class MapPointPickerScreen extends ConsumerStatefulWidget {
  const MapPointPickerScreen({super.key, this.initial, required this.title});

  final GeoPoint? initial;
  final String title;

  @override
  ConsumerState<MapPointPickerScreen> createState() =>
      _MapPointPickerScreenState();
}

class _MapPointPickerScreenState extends ConsumerState<MapPointPickerScreen> {
  MapLibreMapController? _controller;
  late LatLng _center = widget.initial == null
      ? const LatLng(-4.3217, 15.3125) // Kinshasa
      : LatLng(widget.initial!.lat, widget.initial!.lng);

  Future<void> _locateMe() async {
    final location = ref.read(locationServiceProvider);
    if (await location.ensurePermission() != LocationAccess.granted) return;
    final p = await location.current();
    if (p == null) return;
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(p.lat, p.lng), 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MapLibreMap(
            styleString: AppConfig.mapStyleUrl,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: widget.initial == null ? 12 : 15,
            ),
            trackCameraPosition: true,
            onMapCreated: (c) => _controller = c,
            onCameraIdle: () {
              final pos = _controller?.cameraPosition;
              if (pos != null) _center = pos.target;
            },
          ),
          // Viseur : la pointe de l'épingle désigne le centre de la carte.
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Icon(Icons.location_on, size: 48, color: scheme.primary),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: FloatingActionButton.small(
              heroTag: null,
              tooltip: l10n.mapMyPosition,
              onPressed: _locateMe,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: () =>
                    Navigator.of(context)
                        .pop(GeoPoint(_center.latitude, _center.longitude)),
                icon: const Icon(Icons.check),
                label: Text(l10n.mapConfirmPoint),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// « 12,4 km » / « 850 m ».
String formatDistance(double meters) {
  if (meters < 1000) return '${(meters / 10).round() * 10} m';
  final km = meters / 1000;
  final text = km < 100 ? km.toStringAsFixed(1) : km.toStringAsFixed(0);
  return '${text.replaceAll('.', ',')} km';
}
