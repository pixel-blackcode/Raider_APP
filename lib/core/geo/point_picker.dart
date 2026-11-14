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

/// Départ et arrivée pointés sur une même carte (arrivée facultative).
typedef RoutePoints = ({GeoPoint start, GeoPoint? destination});

/// Ouvre le sélecteur ; null si annulé. Une seule carte pour les deux
/// points (ouvrir deux cartes à la suite faisait planter certains Android).
/// Remplaçable en test (pas de rendu natif MapLibre en test de widget).
typedef RoutePicker = Future<RoutePoints?> Function(
  BuildContext context, {
  GeoPoint? start,
  GeoPoint? destination,
});

final routePickerProvider = Provider<RoutePicker>(
  (ref) =>
      (context, {start, destination}) =>
          Navigator.of(context, rootNavigator: true).push<RoutePoints>(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) =>
                  MapRoutePickerScreen(start: start, destination: destination),
            ),
          ),
);

/// Carte plein écran en deux étapes : on place le départ sous l'épingle,
/// on valide, puis de même pour l'arrivée (ou « Sans arrivée »).
class MapRoutePickerScreen extends ConsumerStatefulWidget {
  const MapRoutePickerScreen({super.key, this.start, this.destination});

  final GeoPoint? start;
  final GeoPoint? destination;

  @override
  ConsumerState<MapRoutePickerScreen> createState() =>
      _MapRoutePickerScreenState();
}

class _MapRoutePickerScreenState extends ConsumerState<MapRoutePickerScreen> {
  MapLibreMapController? _controller;
  bool _styleReady = false;
  GeoPoint? _start;
  late LatLng _center = widget.start == null
      ? const LatLng(-4.3217, 15.3125) // Kinshasa
      : LatLng(widget.start!.lat, widget.start!.lng);

  bool get _choosingDestination => _start != null;

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  Future<void> _locateMe() async {
    final location = ref.read(locationServiceProvider);
    if (await location.ensurePermission() != LocationAccess.granted) return;
    final p = await location.current();
    if (p == null || !mounted) return;
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(p.lat, p.lng), 16),
    );
  }

  Future<void> _confirm() async {
    final point = GeoPoint(_center.latitude, _center.longitude);
    if (!_choosingDestination) {
      setState(() => _start = point);
      final c = _controller;
      if (c != null && _styleReady) {
        try {
          await c.addCircle(
            CircleOptions(
              geometry: _center,
              circleRadius: 9,
              circleColor: '#15803d',
              circleStrokeColor: '#ffffff',
              circleStrokeWidth: 3,
            ),
          );
          if (widget.destination != null) {
            await c.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(widget.destination!.lat, widget.destination!.lng),
              ),
            );
          }
        } catch (_) {
          // Le marqueur est un confort : jamais bloquant.
        }
      }
      return;
    }
    Navigator.of(context)
        .pop<RoutePoints>((start: _start!, destination: point));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _choosingDestination ? l10n.mapStepDestination : l10n.mapStepStart,
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MapLibreMap(
            styleString: AppConfig.mapStyleUrl,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: widget.start == null ? 12 : 15,
            ),
            trackCameraPosition: true,
            onMapCreated: (c) => _controller = c,
            onStyleLoadedCallback: () => _styleReady = true,
            onCameraIdle: () {
              final pos = _controller?.cameraPosition;
              if (pos != null) _center = pos.target;
            },
          ),
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Icon(
                _choosingDestination ? Icons.flag : Icons.location_on,
                size: 48,
                color: _choosingDestination ? scheme.error : scheme.primary,
              ),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    key: const Key('map-confirm'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: _confirm,
                    icon: const Icon(Icons.check),
                    label: Text(
                      _choosingDestination
                          ? l10n.mapConfirmDestination
                          : l10n.mapConfirmStart,
                    ),
                  ),
                  if (_choosingDestination)
                    TextButton(
                      key: const Key('map-skip-destination'),
                      onPressed: () => Navigator.of(
                        context,
                      ).pop<RoutePoints>((start: _start!, destination: null)),
                      child: Text(l10n.mapNoDestination),
                    ),
                ],
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
