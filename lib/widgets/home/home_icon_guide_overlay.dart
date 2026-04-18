import 'package:flutter/material.dart';

/// Where to place the description panel relative to the spotlight target.
enum GuidePanelPlacement {
  /// Default behavior: place below target; if it overflows, place above.
  belowThenAbove,

  /// Force above the target (clamped into screen).
  above,

  /// Place the panel inside the target spotlight area, near the top.
  /// Useful for large targets near the bottom (e.g., calculator) to avoid clipping.
  insideTop,
}

/// Darkens the whole screen except a highlighted [targetKey] widget and a
/// description panel placed below it. Tapping anywhere advances.
class HomeIconGuideOverlay extends StatefulWidget {
  final GlobalKey targetKey;
  final String title;
  final String body;
  final String footer;
  final VoidCallback onNext;
  final bool isEnglish;
  final GuidePanelPlacement panelPlacement;
  final double? panelHeightOverride;

  const HomeIconGuideOverlay({
    super.key,
    required this.targetKey,
    required this.title,
    required this.body,
    required this.footer,
    required this.onNext,
    this.isEnglish = false,
    this.panelPlacement = GuidePanelPlacement.belowThenAbove,
    this.panelHeightOverride,
  });

  @override
  State<HomeIconGuideOverlay> createState() => _HomeIconGuideOverlayState();
}

class _HomeIconGuideOverlayState extends State<HomeIconGuideOverlay> {
  Rect? _targetRect;
  Rect? _panelRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recomputeRects());
  }

  @override
  void didUpdateWidget(covariant HomeIconGuideOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetKey != widget.targetKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recomputeRects());
    }
  }

  void _recomputeRects() {
    if (!mounted) return;

    final targetContext = widget.targetKey.currentContext;
    final overlayBox = context.findRenderObject() as RenderBox?;
    final targetBox = targetContext?.findRenderObject() as RenderBox?;

    if (overlayBox == null || targetBox == null || !targetBox.hasSize) return;

    final targetTopLeftGlobal = targetBox.localToGlobal(Offset.zero);
    final targetTopLeft = overlayBox.globalToLocal(targetTopLeftGlobal);
    final targetRect = targetTopLeft & targetBox.size;

    final size = overlayBox.size;
    final panelWidth = (size.width * 0.86).clamp(260.0, 520.0);
    // Default panel height for the 8-icon guide.
    // Increase by ~1 line for better readability.
    final defaultPanelHeight = widget.isEnglish ? 172.0 : 152.0;
    const gap = 10.0;

    final proposedLeft = targetRect.center.dx - panelWidth / 2;
    final clampedLeft = proposedLeft.clamp(12.0, size.width - panelWidth - 12.0);

    double panelHeight = (widget.panelHeightOverride ?? defaultPanelHeight)
        .clamp(96.0, size.height - 24.0);
    double top;
    switch (widget.panelPlacement) {
      case GuidePanelPlacement.above:
        top = (targetRect.top - gap - panelHeight).clamp(12.0, size.height - panelHeight - 12.0);
        break;
      case GuidePanelPlacement.insideTop:
        // Keep the panel within the spotlight target as much as possible.
        // If the target is too small, fall back to the default behavior.
        final availableInTarget = targetRect.height - 20.0;
        if (availableInTarget >= 96.0) {
          panelHeight = panelHeight.clamp(96.0, availableInTarget);
          top = (targetRect.top + 10.0).clamp(12.0, size.height - panelHeight - 12.0);
        } else {
          top = targetRect.bottom + gap;
          if (top + panelHeight > size.height - 12.0) {
            top = (targetRect.top - gap - panelHeight).clamp(12.0, size.height - panelHeight - 12.0);
          }
        }
        break;
      case GuidePanelPlacement.belowThenAbove:
      default:
        top = targetRect.bottom + gap;
        if (top + panelHeight > size.height - 12.0) {
          // If it overflows at bottom, try placing it above the target.
          top = (targetRect.top - gap - panelHeight).clamp(12.0, size.height - panelHeight - 12.0);
        }
        break;
    }

    setState(() {
      _targetRect = targetRect.inflate(8);
      _panelRect = Rect.fromLTWH(clampedLeft.toDouble(), top.toDouble(), panelWidth.toDouble(), panelHeight);
    });
  }

  @override
  Widget build(BuildContext context) {
    final targetRect = _targetRect;
    final panelRect = _panelRect;
    final size = MediaQuery.of(context).size;
    final titleFontSize = widget.isEnglish ? 17.5 : 16.0;
    // Slightly larger body text for better readability (esp. JP).
    final bodyFontSize = widget.isEnglish ? 16.5 : 14.5;
    final footerFontSize = widget.isEnglish ? 13.5 : 12.5;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onNext,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SpotlightPainter(
                targetRect: targetRect,
                panelRect: panelRect,
              ),
            ),
          ),
          if (targetRect != null)
            Positioned.fromRect(
              rect: targetRect,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade300, width: 2),
                  ),
                ),
              ),
            ),
          if (panelRect != null)
            Positioned(
              left: panelRect.left,
              top: panelRect.top,
              width: panelRect.width,
              height: panelRect.height,
              child: IgnorePointer(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      // Solid white fill (user request) to maximize legibility.
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.black87),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: Text(
                                widget.body,
                                style: TextStyle(fontSize: bodyFontSize, height: 1.25),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              widget.footer,
                              style: TextStyle(
                                fontSize: footerFontSize,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Safety: if we couldn't compute rects yet, show a tiny hint at bottom.
          if (targetRect == null || panelRect == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    widget.footer,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
          // Avoid accidental bottom system gesture overlap on tiny screens
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).padding.bottom,
            child: const SizedBox.shrink(),
          ),
          // Keep full-screen semantics
          Positioned(
            left: 0,
            top: 0,
            width: size.width,
            height: 1,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final Rect? panelRect;

  _SpotlightPainter({
    required this.targetRect,
    required this.panelRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final darkPaint = Paint()..color = Colors.black.withOpacity(0.78);
    final clearPaint = Paint()..blendMode = BlendMode.clear;

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, darkPaint);

    if (targetRect != null) {
      final rrect = RRect.fromRectAndRadius(targetRect!, const Radius.circular(18));
      canvas.drawRRect(rrect, clearPaint);
    }
    if (panelRect != null) {
      final rrect = RRect.fromRectAndRadius(panelRect!, const Radius.circular(16));
      canvas.drawRRect(rrect, clearPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect || oldDelegate.panelRect != panelRect;
  }
}


