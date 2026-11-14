import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Visionneuse plein écran : glisser pour changer de photo, pincer ou
/// toucher deux fois pour zoomer (jusqu'à ×5), puis déplacer l'image.
Future<void> openPhotoViewer(
  BuildContext context, {
  required List<ImageProvider?> images,
  int initialIndex = 0,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: true,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) =>
          PhotoViewer(images: images, initialIndex: initialIndex),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class PhotoViewer extends StatefulWidget {
  const PhotoViewer({super.key, required this.images, this.initialIndex = 0});

  final List<ImageProvider?> images;
  final int initialIndex;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  /// Pendant un zoom, le glissement déplace l'image au lieu de changer de page.
  bool _zoomed = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const Key('photo-viewer'),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            physics: _zoomed
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => _ZoomablePhoto(
              image: widget.images[i],
              onZoomChanged: (z) {
                if (z != _zoomed) setState(() => _zoomed = z);
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    key: const Key('photo-viewer-close'),
                    tooltip: l10n.actionClose,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                  const Spacer(),
                  if (widget.images.length > 1)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          '${_index + 1} / ${widget.images.length}',
                          key: const Key('photo-viewer-index'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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

class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({required this.image, required this.onZoomChanged});

  final ImageProvider? image;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto>
    with SingleTickerProviderStateMixin {
  final _controller = TransformationController();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<Matrix4>? _tween;
  TapDownDetails? _doubleTap;

  @override
  void initState() {
    super.initState();
    _anim.addListener(() {
      if (_tween != null) _controller.value = _tween!.value;
    });
    _controller.addListener(() {
      widget.onZoomChanged(_controller.value.getMaxScaleOnAxis() > 1.01);
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    final zoomed = _controller.value.getMaxScaleOnAxis() > 1.01;
    final Matrix4 target;
    if (zoomed) {
      target = Matrix4.identity();
    } else {
      final p = _doubleTap?.localPosition ?? Offset.zero;
      const scale = 2.5;
      target = Matrix4.identity()
        ..translateByDouble(-p.dx * (scale - 1), -p.dy * (scale - 1), 0, 1)
        ..scaleByDouble(scale, scale, 1, 1);
    }
    _tween = Matrix4Tween(
      begin: _controller.value,
      end: target,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    const placeholder = Center(
      child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
    );
    return GestureDetector(
      onDoubleTapDown: (d) => _doubleTap = d,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1,
        maxScale: 5,
        child: SizedBox.expand(
          child: widget.image == null
              ? placeholder
              : Image(
                  image: widget.image!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => placeholder,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                ),
        ),
      ),
    );
  }
}
