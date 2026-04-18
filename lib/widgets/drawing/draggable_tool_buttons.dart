// lib/widgets/draggable_tool_buttons.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../constants/app_constants.dart';
import '../../localization/app_localizations.dart';

/// ドラッグ可能なペンボタン（パレット付き）
class DraggablePenButton extends StatefulWidget {
  final Offset position;
  final bool isSelected;
  final Color currentColor;
  final double currentStrokeWidth;
  final ValueChanged<Offset> onPositionChanged;
  final VoidCallback onPenModeChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;
  final ValueListenable<String>? activeToolNotifier;
  final ValueListenable<bool>? isDrawingNotifier;

  const DraggablePenButton({
    super.key,
    required this.position,
    required this.isSelected,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.onPositionChanged,
    required this.onPenModeChanged,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    this.activeToolNotifier,
    this.isDrawingNotifier,
  });

  @override
  State<DraggablePenButton> createState() => _DraggablePenButtonState();
}

class _DraggablePenButtonState extends State<DraggablePenButton> {
  bool _isPaletteExpanded = false;
  VoidCallback? _activeToolListener;
  VoidCallback? _isDrawingListener;
  Timer? _savePositionTimer;
  Offset _currentPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.position;
    _attachNotifiers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPosition();
    });
  }

  @override
  void didUpdateWidget(covariant DraggablePenButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeToolNotifier != widget.activeToolNotifier ||
        oldWidget.isDrawingNotifier != widget.isDrawingNotifier) {
      _detachNotifiers(oldWidget);
      _attachNotifiers();
    }
  }

  @override
  void dispose() {
    _detachNotifiers(widget);
    _savePositionTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final savedX = prefs.getDouble('draggable_pen_button_x');
    final savedY = prefs.getDouble('draggable_pen_button_y');
    
    if (mounted) {
      if (savedX != null && savedY != null) {
        // 保存された位置がある場合はそれを使用
        setState(() {
          _currentPosition = Offset(savedX, savedY);
        });
        widget.onPositionChanged(_currentPosition);
      } else if (widget.position == Offset.zero) {
        // 保存された位置がなく、親から渡された位置も(0,0)の場合は画面中央に配置
        final screenSize = MediaQuery.of(context).size;
        final isMobile = screenSize.width < 600;
        final buttonSize = isMobile ? 56.0 : 72.0;
        final spacing = isMobile ? 40.0 : 60.0;
        
        // 画面中央を基準に、ペンボタンを左側に配置
        final centerX = screenSize.width / 2;
        final centerY = screenSize.height / 2;
        final eraserX = centerX - buttonSize / 2;
        final eraserY = centerY - buttonSize / 2;
        final penX = eraserX - buttonSize - spacing;
        final penY = eraserY;
        
        setState(() {
          _currentPosition = Offset(penX, penY);
        });
        widget.onPositionChanged(_currentPosition);
      } else {
        // 親から渡された位置を使用
      setState(() {
          _currentPosition = widget.position;
      });
      widget.onPositionChanged(_currentPosition);
      }
    }
  }

  Future<void> _savePosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('draggable_pen_button_x', _currentPosition.dx);
    await prefs.setDouble('draggable_pen_button_y', _currentPosition.dy);
  }

  void _attachNotifiers() {
    if (widget.activeToolNotifier != null) {
      _activeToolListener = () {
        final val = widget.activeToolNotifier!.value;
        // pen 以外に切り替わったらパレットを閉じる
        if (_isPaletteExpanded && val != 'pen') {
          setState(() {
            _isPaletteExpanded = false;
          });
        }
      };
      widget.activeToolNotifier!.addListener(_activeToolListener!);
    }
    if (widget.isDrawingNotifier != null) {
      _isDrawingListener = () {
        final drawing = widget.isDrawingNotifier!.value;
        if (_isPaletteExpanded && drawing) {
          setState(() {
            _isPaletteExpanded = false;
          });
        }
      };
      widget.isDrawingNotifier!.addListener(_isDrawingListener!);
    }
  }

  void _detachNotifiers(DraggablePenButton sourceWidget) {
    if (_activeToolListener != null && sourceWidget.activeToolNotifier != null) {
      sourceWidget.activeToolNotifier!.removeListener(_activeToolListener!);
      _activeToolListener = null;
    }
    if (_isDrawingListener != null && sourceWidget.isDrawingNotifier != null) {
      sourceWidget.isDrawingNotifier!.removeListener(_isDrawingListener!);
      _isDrawingListener = null;
    }
  }

  // 領域制限を撤廃したため、このメソッドは使用されません
  // void _ensureWithinBounds() {
  //   // 領域制限を撤廃
  // }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final buttonSize = isMobile ? 56.0 : 72.0;
    final iconSize = isMobile ? 28.0 : 36.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: _currentPosition.dx,
          top: _currentPosition.dy,
          child: SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onPanStart: (_) {
                FocusScope.of(context).unfocus();
              },
              onPanUpdate: (details) {
                setState(() {
                  _currentPosition = _currentPosition + details.delta;
                });
                widget.onPositionChanged(_currentPosition);
                
                // デバウンスして位置を保存
                _savePositionTimer?.cancel();
                _savePositionTimer = Timer(const Duration(milliseconds: 500), _savePosition);
              },
              onPanEnd: (_) {
                _savePosition();
              },
              child: Material(
                elevation: 20,
                shape: const CircleBorder(),
                child: InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: () {
                    if (_isPaletteExpanded) {
                      setState(() {
                        _isPaletteExpanded = false;
                      });
                    } else {
                      widget.onPenModeChanged();
                      setState(() {
                        _isPaletteExpanded = true;
                      });
                    }
                  },
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      color: widget.isSelected ? Colors.green[600] : Colors.grey[600],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        if (_isPaletteExpanded)
          Positioned(
            left: _calcPaletteLeft(context, _currentPosition.dx),
            top: _calcPaletteTop(context, _currentPosition.dy),
            child: Material(
              elevation: 25,
              borderRadius: BorderRadius.circular(12),
              child: _buildPenPalette(),
            ),
          ),
      ],
    );
  }

  double _calcPaletteLeft(BuildContext context, double buttonLeft) {
    final screenWidth = MediaQuery.of(context).size.width;
    const paletteWidth = 220.0;
    double left = buttonLeft;
    if (left + paletteWidth > screenWidth - 8) {
      left = (screenWidth - paletteWidth - 8).clamp(8.0, screenWidth - paletteWidth);
    }
    if (left < 8) left = 8;
    return left;
  }

  double _calcPaletteTop(BuildContext context, double buttonTop) {
    final screenHeight = MediaQuery.of(context).size.height;
    // 太さUIを廃止し、色2行だけにしたので高さを縮める
    const paletteHeight = 140.0;
    double top = buttonTop + 72;
    if (top + paletteHeight > screenHeight - 8) {
      top = (buttonTop - paletteHeight - 8).clamp(8.0, screenHeight - 8);
    }
    if (top < 8) top = 8;
    return top;
  }

  Widget _buildPenPalette() {
    final l10n = AppLocalizations.of(context);
    final colors = AppConstants.availableColors;
    final splitIndex = (colors.length / 2).ceil();
    final firstRow = colors.take(splitIndex).toList();
    final secondRow = colors.skip(splitIndex).toList();
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.drawingColor,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: firstRow.map((color) {
                  final isSelected = widget.currentColor == color;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onColorChanged(color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey[300]!,
                            width: isSelected ? 3 : 2,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: secondRow.map((color) {
                  final isSelected = widget.currentColor == color;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onColorChanged(color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey[300]!,
                            width: isSelected ? 3 : 2,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// 共通のドラッグ可能ツールボタン（Stateful に変更して補正処理を入れる）
class DraggableToolButton extends StatefulWidget {
  final Offset position;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<Offset> onPositionChanged;

  const DraggableToolButton({
    super.key,
    required this.position,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.onPositionChanged,
  });

  @override
  State<DraggableToolButton> createState() => _DraggableToolButtonState();
}

class _DraggableToolButtonState extends State<DraggableToolButton> {
  Timer? _savePositionTimer;
  Offset _currentPosition = Offset.zero;
  String _positionKey = '';

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.position;
    // アイコンに基づいて位置キーを決定
    if (widget.icon == Icons.auto_fix_high) {
      _positionKey = 'draggable_eraser_button';
    } else if (widget.icon == Icons.pan_tool) {
      _positionKey = 'draggable_scroll_button';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureWithinBounds();
      if (_positionKey.isNotEmpty) {
        _loadPosition();
      }
    });
  }

  @override
  void didUpdateWidget(covariant DraggableToolButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.position != oldWidget.position) {
      _currentPosition = widget.position;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureWithinBounds());
  }

  @override
  void dispose() {
    _savePositionTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPosition() async {
    if (_positionKey.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble('${_positionKey}_x');
    final y = prefs.getDouble('${_positionKey}_y');
    if (x != null && y != null && mounted) {
      setState(() {
        _currentPosition = Offset(x, y);
      });
      widget.onPositionChanged(_currentPosition);
    }
  }

  Future<void> _savePosition() async {
    if (_positionKey.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${_positionKey}_x', _currentPosition.dx);
    await prefs.setDouble('${_positionKey}_y', _currentPosition.dy);
  }

  void _ensureWithinBounds() {
    if (!mounted) return;
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final buttonSize = isMobile ? 56.0 : 72.0;
    const edgeMargin = 35.0;
    final minX = edgeMargin;
    final maxX = screenSize.width - buttonSize - edgeMargin;
    final minY = edgeMargin;
    final maxY = screenSize.height - buttonSize - edgeMargin;

    final clampedX = _currentPosition.dx.clamp(minX, maxX);
    final clampedY = _currentPosition.dy.clamp(minY, maxY);
    final clamped = Offset(clampedX, clampedY);
    if (clamped != _currentPosition) {
      setState(() {
        _currentPosition = clamped;
      });
      widget.onPositionChanged(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final buttonSize = isMobile ? 56.0 : 72.0;
    final iconSize = isMobile ? 28.0 : 36.0;

    return Positioned(
      left: _currentPosition.dx,
      top: _currentPosition.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onPanStart: (_) {
          FocusScope.of(context).unfocus();
        },
        onPanUpdate: (details) {
          setState(() {
            final newPosition = _currentPosition + details.delta;
            const edgeMargin = 35.0;
            final clampedX = newPosition.dx.clamp(
              edgeMargin,
              screenSize.width - buttonSize - edgeMargin,
            );
            final clampedY = newPosition.dy.clamp(
              edgeMargin,
              screenSize.height - buttonSize - edgeMargin,
            );
            _currentPosition = Offset(clampedX, clampedY);
          });
          widget.onPositionChanged(_currentPosition);
          
          // デバウンスして位置を保存
          _savePositionTimer?.cancel();
          _savePositionTimer = Timer(const Duration(milliseconds: 500), _savePosition);
        },
        onPanEnd: (_) {
          _ensureWithinBounds();
          _savePosition();
        },
        child: Material(
          elevation: 20,
          shape: const CircleBorder(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: widget.isSelected ? Colors.green[600] : Colors.grey[600],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: iconSize),
            ),
          ),
        ),
      ),
    );
  }
}
