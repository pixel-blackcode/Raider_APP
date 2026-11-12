import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/config/app_config.dart';
import '../domain/convoy.dart';

/// Construit la carte du convoi. Surchargé dans les tests (pas de rendu
/// natif MapLibre en test de widget).
typedef ConvoyMapBuilder = Widget Function(
  List<ConvoyMember> members,
  String? meId,
);

final convoyMapBuilderProvider = Provider<ConvoyMapBuilder>(
  (ref) =>
      (members, meId) => ConvoyMap(members: members, meId: meId),
);

/// Carte MapLibre (OpenStreetMap) avec un point par participant qui partage.
class ConvoyMap extends StatefulWidget {
  const ConvoyMap({super.key, required this.members, this.meId});

  final List<ConvoyMember> members;
  final String? meId;

  @override
  State<ConvoyMap> createState() => _ConvoyMapState();
}

class _ConvoyMapState extends State<ConvoyMap> {
  MapLibreMapController? _controller;
  bool _styleReady = false;
  bool _centered = false;

  // Kinshasa par défaut, avant la première position.
  static const _fallback = LatLng(-4.3217, 15.3125);

  @override
  void didUpdateWidget(ConvoyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _drawMarkers();
  }

  String _color(ConvoyMember m) {
    if (m.alert == ConvoyAlert.staleSignal) return '#8a8a8a';
    if (m.alert == ConvoyAlert.possiblySeparated) return '#d97706';
    return switch (m.role) {
      ConvoyRole.leader => '#c2410c',
      ConvoyRole.sweeper => '#1d4ed8',
      null => m.userId == widget.meId ? '#15803d' : '#1d1a19',
    };
  }

  Future<void> _drawMarkers() async {
    final c = _controller;
    if (c == null || !_styleReady) return;
    await c.clearCircles();
    final sharing = widget.members.where((m) => m.position != null).toList();
    for (final m in sharing) {
      await c.addCircle(
        CircleOptions(
          geometry: LatLng(m.position!.lat, m.position!.lng),
          circleRadius: m.role == null ? 8 : 11,
          circleColor: _color(m),
          circleStrokeColor: '#ffffff',
          circleStrokeWidth: 3,
          circleOpacity: m.alert == ConvoyAlert.staleSignal ? 0.5 : 1,
        ),
      );
    }
    if (!_centered && sharing.isNotEmpty) {
      _centered = true;
      final target = sharing.firstWhere(
        (m) => m.role == ConvoyRole.leader,
        orElse: () => sharing.first,
      );
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(target.position!.lat, target.position!.lng),
          13,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      styleString: AppConfig.mapStyleUrl,
      initialCameraPosition: const CameraPosition(target: _fallback, zoom: 11),
      compassEnabled: true,
      onMapCreated: (c) => _controller = c,
      onStyleLoadedCallback: () {
        _styleReady = true;
        _drawMarkers();
      },
    );
  }
}
