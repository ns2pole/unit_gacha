import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../pages/other/scratch_paper_page.dart' show DrawingPainter, DrawingPoint;

class DrawingCanvas extends StatefulWidget {
  final bool isEraser;
  final bool isScrollMode;
  final bool isLassoTool;
  final bool isMarkerTool;
  final Color markerBaseColor;
  final double eraserRadius;
  final bool isIPadDevice;
  final bool allowFingerDrawing;
  final Color currentColor;
  final double currentStrokeWidth;
  final ValueNotifier<bool>? isDrawingNotifier;
  final double width;
  final double height;

  const DrawingCanvas({
    Key? key,
    required this.isEraser,
    required this.isScrollMode,
    this.isLassoTool = false,
    this.isMarkerTool = false,
    this.markerBaseColor = Colors.yellow,
    this.eraserRadius = 20.0,
    this.isIPadDevice = false,
    this.allowFingerDrawing = true,
    required this.currentColor,
    required this.currentStrokeWidth,
    this.isDrawingNotifier,
    this.width = 2000,
    this.height = 2000,
  }) : super(key: key);

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final GlobalKey _paintKey = GlobalKey();
  List<DrawingPoint> _points = [];
  List<List<DrawingPoint>> _strokes = [];
  List<List<DrawingPoint>> _undoStack = [];
  List<List<DrawingPoint>> _redoStack = [];

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  PointerDeviceKind? _activePointerKind;
  int? _consumedPointer; // a tap used only for deselection; ignore rest of sequence

  // Lasso / selection state
  bool _isLassoSelecting = false;
  List<Offset> _lassoPath = [];
  bool _isLassoPending = false;
  Offset? _lassoPendingStart;
  int? _lassoPointer;
  static const double _lassoStartSlop = 6.0;
  Set<int> _selectedStrokeIndices = {};
  Rect? _selectionBounds;
  Offset? _selectionCenter;

  // Move
  Offset? _selectionOffset;

  // Scale (handles)
  int? _selectedHandleIndex; // 0:LT 1:RT 2:LB 3:RB
  Offset? _handleDragStart;
  Rect? _originalSelectionBounds;
  Offset? _originalSelectionCenter;
  double _selectionScale = 1.0;
  final Map<int, List<Offset>> _originalStrokePositions = {};

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DrawingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Lasso tool → non-lasso tool: stop drawing lasso path (selection stays).
    if (oldWidget.isLassoTool && !widget.isLassoTool) {
      if (_isLassoSelecting || _lassoPath.isNotEmpty) {
        setState(() {
          _isLassoSelecting = false;
          _lassoPath.clear();
        });
      }
    }
  }

  // 筆圧から線幅を計算する関数
  double _calculateStrokeWidth(double pressure) {
    if (widget.isMarkerTool) {
      // Marker: fixed width (requested)
      return 16.0;
    }
    if (pressure <= 0.0) {
      return widget.currentStrokeWidth; // デフォルト値（筆圧なし）
    }
    const minWidth = 1.0;
    const maxWidth = 8.0;
    // 筆圧値（0.0〜1.0）を線幅にマッピング
    return minWidth + (pressure * (maxWidth - minWidth));
  }

  Color _effectiveDrawColor() {
    if (widget.isMarkerTool) {
      return widget.markerBaseColor.withOpacity(0.3);
    }
    return widget.currentColor;
  }

  bool _calculateShouldEnableScroll() {
    // Explicit scroll tool wins.
    if (widget.isScrollMode) return true;

    // While lasso tool is active or selection manipulation is in progress, prefer selection interactions.
    if (widget.isLassoTool) return false;
    if (_isLassoSelecting) return false;
    if (_selectedStrokeIndices.isNotEmpty) return false;

    // iPad: finger scrolling by default when finger drawing is disabled.
    if (widget.isIPadDevice && !widget.allowFingerDrawing) {
      if (_activePointerKind == PointerDeviceKind.stylus) return false;
      // touch or no active pointer → allow scroll so the drag gesture works immediately.
      return true;
    }

    return false;
  }

  bool _shouldIgnoreDrawingForPointer(PointerDeviceKind kind) {
    // iPad: if finger drawing is disabled, ignore touch drawing unless lasso/selection is active.
    if (widget.isIPadDevice && !widget.allowFingerDrawing && kind == PointerDeviceKind.touch) {
      if (widget.isLassoTool) return false;
      if (_selectedStrokeIndices.isNotEmpty) return false;
      return true;
    }
    return false;
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _activePointerKind = event.kind;
    });

    // If scroll should take this gesture, do not start drawing.
    if (_shouldIgnoreDrawingForPointer(event.kind)) return;
    if (_calculateShouldEnableScroll()) return;

    // Selection interactions take priority.
    if (_selectedStrokeIndices.isNotEmpty) {
      _selectionBounds = _calculateSelectionBounds();
      _selectionCenter = _calculateSelectionCenter();

      final bounds = _selectionBounds;
      if (bounds != null) {
        final handleIndex = _getHandleAtPosition(event.localPosition);
        if (handleIndex != null) {
          // Start scaling from original snapshot.
          _originalStrokePositions
            ..clear()
            ..addAll(_snapshotSelectedStrokePositions());
        widget.isDrawingNotifier?.value = true;
          setState(() {
            _selectedHandleIndex = handleIndex;
            _handleDragStart = event.localPosition;
            _originalSelectionBounds = bounds;
            _originalSelectionCenter = _selectionCenter;
            _selectionScale = 1.0;
            _selectionOffset = null; // disable move during scale
          });
          return;
        }

        if (bounds.contains(event.localPosition)) {
          widget.isDrawingNotifier?.value = true;
          _selectionOffset = event.localPosition;
          return;
        }
      }

      // Tap outside selection → clear selection and CONSUME the gesture.
      setState(() {
        _selectedStrokeIndices.clear();
        _selectionBounds = null;
        _selectionCenter = null;
        _selectedHandleIndex = null;
        _handleDragStart = null;
        _selectionOffset = null;
        _originalSelectionBounds = null;
        _originalSelectionCenter = null;
        _selectionScale = 1.0;
        _lassoPath.clear();
        _isLassoSelecting = false;
        _isLassoPending = false;
        _lassoPendingStart = null;
        _lassoPointer = null;
        _originalStrokePositions.clear();
        _consumedPointer = event.pointer;
      });
      return;
    }

    // Lasso tool
    if (widget.isLassoTool) {
      // Treat lasso interaction as "drawing" to disable parent scroll immediately.
      widget.isDrawingNotifier?.value = true;
      setState(() {
        // Defer lasso start until drag exceeds a small threshold.
        _isLassoPending = true;
        _lassoPendingStart = event.localPosition;
        _lassoPointer = event.pointer;
        _isLassoSelecting = false;
        _lassoPath.clear();
      });
      return;
    }

    final pressure = event.pressure;
    final strokeWidth = _calculateStrokeWidth(pressure);

    widget.isDrawingNotifier?.value = true;

    setState(() {
      _points = [
        DrawingPoint(
          event.localPosition,
          _effectiveDrawColor(),
          strokeWidth,
          widget.isEraser,
        ),
      ];
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_consumedPointer == event.pointer) return;

    // If scroll should take this gesture, do not draw.
    if (_shouldIgnoreDrawingForPointer(event.kind)) return;
    if (_calculateShouldEnableScroll()) return;

    // Lasso: keep capturing path.
    if (widget.isLassoTool) {
      if (_isLassoPending && _lassoPointer == event.pointer && _lassoPendingStart != null) {
        final start = _lassoPendingStart!;
        final delta = (event.localPosition - start).distance;
        if (delta >= _lassoStartSlop) {
          setState(() {
            _isLassoPending = false;
            _isLassoSelecting = true;
            _lassoPath = [start, event.localPosition];
          });
        }
        return;
      }
      if (_isLassoSelecting) {
        setState(() {
          _lassoPath.add(event.localPosition);
        });
        return;
      }
    }

    // Scale handles.
    if (_selectedStrokeIndices.isNotEmpty &&
        _selectedHandleIndex != null &&
        _handleDragStart != null &&
        _originalSelectionBounds != null &&
        _originalSelectionCenter != null) {
      final originalBounds = _originalSelectionBounds!;
      final originalCenter = _originalSelectionCenter!;
      final startPos = _handleDragStart!;
      final currentPos = event.localPosition;

      final originalHandles = <Offset>[
        Offset(originalBounds.left, originalBounds.top),
        Offset(originalBounds.right, originalBounds.top),
        Offset(originalBounds.left, originalBounds.bottom),
        Offset(originalBounds.right, originalBounds.bottom),
      ];

      final handleStartPos = originalHandles[_selectedHandleIndex!];
      final handleCurrentPos = handleStartPos + (currentPos - startPos);

      final startDistance = (handleStartPos - originalCenter).distance;
      final currentDistance = (handleCurrentPos - originalCenter).distance;
      if (startDistance <= 0.01) return;

      // Clamp to avoid flips / huge jumps.
      final scale = (currentDistance / startDistance).clamp(0.5, 3.0);

      // Apply scale from the original snapshot to avoid compounding errors.
      widget.isDrawingNotifier?.value = true;
      setState(() {
        _selectionScale = scale;
        _scaleSelectedStrokesFromOriginal(scale, originalCenter);
        _selectionBounds = _calculateSelectionBounds();
        _selectionCenter = _calculateSelectionCenter();
      });
      return;
    }

    // Move selection.
    if (_selectedStrokeIndices.isNotEmpty && _selectionOffset != null) {
      final delta = event.localPosition - _selectionOffset!;
      if (delta.distanceSquared <= 0) return;
      setState(() {
        for (final index in _selectedStrokeIndices) {
          if (index < _strokes.length) {
            for (final p in _strokes[index]) {
              p.point += delta;
            }
          }
        }
        _selectionOffset = event.localPosition;
        _selectionBounds = _calculateSelectionBounds();
        _selectionCenter = _calculateSelectionCenter();
      });
      return;
    }

    final pressure = event.pressure;
    final strokeWidth = _calculateStrokeWidth(pressure);

    if (widget.isEraser) {
      _eraseAtPoint(event.localPosition);
    } else {
      setState(() {
        _points.add(
          DrawingPoint(
            event.localPosition,
            _effectiveDrawColor(),
            strokeWidth,
            false,
          ),
        );
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    widget.isDrawingNotifier?.value = false;

    setState(() {
      _activePointerKind = null;
    });

    if (_consumedPointer == event.pointer) {
      setState(() {
        _consumedPointer = null;
      });
      return;
    }

    // If finger drawing is disabled and this was a finger gesture for scrolling, do nothing.
    if (_shouldIgnoreDrawingForPointer(event.kind)) return;

    // End lasso selection.
    if (widget.isLassoTool) {
      // Tap while in lasso mode (pending but never started) should cancel path and clear selection.
      if (_isLassoPending && _lassoPointer == event.pointer) {
        setState(() {
          _isLassoPending = false;
          _lassoPendingStart = null;
          _lassoPointer = null;
          _isLassoSelecting = false;
          _lassoPath.clear();
          _selectedStrokeIndices.clear();
          _selectionBounds = null;
          _selectionCenter = null;
          _selectionOffset = null;
          _selectedHandleIndex = null;
          _handleDragStart = null;
          _originalSelectionBounds = null;
          _originalSelectionCenter = null;
          _selectionScale = 1.0;
          _originalStrokePositions.clear();
        });
        widget.isDrawingNotifier?.value = false;
        return;
      }

      if (_isLassoSelecting) {
        setState(() {
          _isLassoSelecting = false;
        });
        if (_lassoPath.length >= 3) {
          _selectStrokesInLasso();
        } else {
          // Drag was too small; treat as cancel.
          setState(() {
            _selectedStrokeIndices.clear();
            _selectionBounds = null;
            _selectionCenter = null;
            _originalStrokePositions.clear();
          });
        }
        setState(() {
          _lassoPath.clear();
          _lassoPointer = null;
          _lassoPendingStart = null;
          _isLassoPending = false;
        });
        widget.isDrawingNotifier?.value = false;
        return;
      }
    }

    // End scaling.
    if (_selectedStrokeIndices.isNotEmpty && _selectedHandleIndex != null) {
      setState(() {
        _selectedHandleIndex = null;
        _handleDragStart = null;
        _originalSelectionBounds = null;
        _originalSelectionCenter = null;
        _selectionScale = 1.0;
        // Refresh snapshot to the new positions.
        _originalStrokePositions
          ..clear()
          ..addAll(_snapshotSelectedStrokePositions());
        _selectionBounds = _calculateSelectionBounds();
        _selectionCenter = _calculateSelectionCenter();
      });
      widget.isDrawingNotifier?.value = false;
      return;
    }

    // End move.
    if (_selectedStrokeIndices.isNotEmpty && _selectionOffset != null) {
      setState(() {
        _selectionOffset = null;
        _selectionBounds = _calculateSelectionBounds();
        _selectionCenter = _calculateSelectionCenter();
      });
      widget.isDrawingNotifier?.value = false;
      return;
    }

    if (!widget.isEraser) {
      setState(() {
        _strokes.add(List.from(_points));
        _points = [];
        _redoStack.clear();
      });
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    widget.isDrawingNotifier?.value = false;
    setState(() {
      _activePointerKind = null;
      _isLassoSelecting = false;
      _lassoPath.clear();
      _isLassoPending = false;
      _lassoPendingStart = null;
      _lassoPointer = null;
      _consumedPointer = null;
      _selectionOffset = null;
      _selectedHandleIndex = null;
      _handleDragStart = null;
      _originalSelectionBounds = null;
      _originalSelectionCenter = null;
      _selectionScale = 1.0;
    });

    if (_shouldIgnoreDrawingForPointer(event.kind)) return;

    if (!widget.isEraser && _points.isNotEmpty) {
      setState(() {
        _strokes.add(List.from(_points));
        _points = [];
        _redoStack.clear();
      });
    }
  }

  Map<int, List<Offset>> _snapshotSelectedStrokePositions() {
    final map = <int, List<Offset>>{};
    for (final index in _selectedStrokeIndices) {
      if (index < _strokes.length) {
        map[index] = _strokes[index].map((p) => Offset(p.point.dx, p.point.dy)).toList();
      }
    }
    return map;
  }

  Offset _calculateSelectionCenter() {
    if (_selectedStrokeIndices.isEmpty) return Offset.zero;
    double totalX = 0;
    double totalY = 0;
    int count = 0;
    for (final index in _selectedStrokeIndices) {
      if (index < _strokes.length) {
        for (final p in _strokes[index]) {
          totalX += p.point.dx;
          totalY += p.point.dy;
          count++;
        }
      }
    }
    if (count == 0) return Offset.zero;
    return Offset(totalX / count, totalY / count);
  }

  Rect? _calculateSelectionBounds() {
    if (_selectedStrokeIndices.isEmpty) return null;
    double? minX, minY, maxX, maxY;
    for (final index in _selectedStrokeIndices) {
      if (index < _strokes.length) {
        for (final p in _strokes[index]) {
          final x = p.point.dx;
          final y = p.point.dy;
          minX = minX == null ? x : math.min(minX, x);
          minY = minY == null ? y : math.min(minY, y);
          maxX = maxX == null ? x : math.max(maxX, x);
          maxY = maxY == null ? y : math.max(maxY, y);
        }
      }
    }
    if (minX == null || minY == null || maxX == null || maxY == null) return null;
    const padding = 8.0;
    return Rect.fromLTRB(minX - padding, minY - padding, maxX + padding, maxY + padding);
  }

  int? _getHandleAtPosition(Offset position) {
    final bounds = _selectionBounds;
    if (bounds == null) return null;
    const handleTouchRadius = 20.0;
    final handles = <Offset>[
      Offset(bounds.left, bounds.top),
      Offset(bounds.right, bounds.top),
      Offset(bounds.left, bounds.bottom),
      Offset(bounds.right, bounds.bottom),
    ];
    for (int i = 0; i < handles.length; i++) {
      if ((position - handles[i]).distance <= handleTouchRadius) return i;
    }
    return null;
  }

  void _scaleSelectedStrokesFromOriginal(double scale, Offset center) {
    for (final index in _selectedStrokeIndices) {
      if (!_originalStrokePositions.containsKey(index)) continue;
      if (index >= _strokes.length) continue;

      final originalPositions = _originalStrokePositions[index]!;
      final stroke = _strokes[index];
      final minLength = math.min(stroke.length, originalPositions.length);
      for (int i = 0; i < minLength; i++) {
        final originalPoint = originalPositions[i];
        final offset = originalPoint - center;
        stroke[i].point = center + offset * scale;
      }
      if (stroke.length > originalPositions.length && originalPositions.isNotEmpty) {
        final lastOriginalPoint = originalPositions.last;
        final lastOffset = lastOriginalPoint - center;
        for (int i = minLength; i < stroke.length; i++) {
          stroke[i].point = center + lastOffset * scale;
        }
      }
    }
  }

  void _selectStrokesInLasso() {
    if (_lassoPath.length < 3) return;
    final polygon = _lassoPath;
    final selected = <int>{};
    for (int i = 0; i < _strokes.length; i++) {
      final stroke = _strokes[i];
      bool isInside = false;
      for (final p in stroke) {
        if (_isPointInPolygon(p.point, polygon)) {
          isInside = true;
          break;
        }
      }
      if (isInside) selected.add(i);
    }

    setState(() {
      _selectedStrokeIndices = selected;
      _selectionScale = 1.0;
      _originalStrokePositions
        ..clear()
        ..addAll(_snapshotSelectedStrokePositions());
      _selectionBounds = _calculateSelectionBounds();
      _selectionCenter = _calculateSelectionCenter();
    });
  }

  bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    if (polygon.length < 3) return false;
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].dx;
      final yi = polygon[i].dy;
      final xj = polygon[j].dx;
      final yj = polygon[j].dy;

      final intersects = ((yi > point.dy) != (yj > point.dy)) &&
          (point.dx < (xj - xi) * (point.dy - yi) / (yj - yi) + xi);
      if (intersects) inside = !inside;
      j = i;
    }
    return inside;
  }

  void _eraseAtPoint(Offset point) {
    setState(() {
      final eraseRadius = widget.eraserRadius;
      final List<List<DrawingPoint>> newStrokes = [];
      
      for (final stroke in _strokes) {
        final List<DrawingPoint> remainingPoints = [];
        bool wasErasing = false;
        
        for (int i = 0; i < stroke.length; i++) {
          final distance = (stroke[i].point - point).distance;
          
          if (distance < eraseRadius) {
            // 消しゴムの範囲内のポイントはスキップ
            wasErasing = true;
          } else {
            // 消しゴムの範囲外のポイント
            if (wasErasing && remainingPoints.isNotEmpty) {
              // 前回の消去範囲から離れたので、新しいストロークとして保存
              if (remainingPoints.length > 1) {
                newStrokes.add(List.from(remainingPoints));
              }
              remainingPoints.clear();
            }
            remainingPoints.add(stroke[i]);
            wasErasing = false;
          }
        }
        
        // 残りのポイントがある場合は追加
        if (remainingPoints.length > 1) {
          newStrokes.add(remainingPoints);
        }
      }
      
      _strokes = newStrokes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shouldEnableScroll = _calculateShouldEnableScroll();
    final shouldClaimGestureArena = widget.isLassoTool ||
        _isLassoPending ||
        _isLassoSelecting ||
        _selectedStrokeIndices.isNotEmpty ||
        _selectedHandleIndex != null ||
        _selectionOffset != null;

    final paint = RepaintBoundary(
      key: _paintKey,
      child: CustomPaint(
        painter: DrawingPainter(
          strokes: _strokes,
          currentStroke: _points,
          lassoPath: _isLassoSelecting ? _lassoPath : null,
          selectedStrokeIndices: _selectedStrokeIndices,
          selectionBounds: _selectionBounds,
        ),
        size: Size(widget.width, widget.height),
      ),
    );

    // During lasso/selection interactions, aggressively claim the gesture arena so parent Scrollables
    // won't hijack the drag and scroll the page/canvas.
    final interactionLayer = shouldClaimGestureArena
        ? RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: <Type, GestureRecognizerFactory>{
              EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                  EagerGestureRecognizer>(
                () => EagerGestureRecognizer(),
                (EagerGestureRecognizer instance) {},
              ),
            },
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: paint,
            ),
          )
        : Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            child: paint,
          );

    return SingleChildScrollView(
      controller: _verticalScrollController,
      scrollDirection: Axis.vertical,
      physics: shouldEnableScroll
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        physics: shouldEnableScroll
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: interactionLayer,
        ),
      ),
    );
  }
}


