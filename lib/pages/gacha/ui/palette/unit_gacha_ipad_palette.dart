// lib/pages/gacha/unit_gacha_ipad_palette.dart
// 単位ガチャページのiPad用ツールパレットUI

import 'package:flutter/material.dart';
import '../../drawing/unit_gacha_drawing_tools.dart' show DrawingTool, DrawingToolState, buildToolIcon;

/// iPad用のツールパレットUI（メモアプリ風）
class UnitGachaIPadPalette extends StatefulWidget {
  final DrawingToolState toolState;
  final ValueNotifier<String> activeToolNotifier;
  final VoidCallback onStateChanged;

  const UnitGachaIPadPalette({
    Key? key,
    required this.toolState,
    required this.activeToolNotifier,
    required this.onStateChanged,
  }) : super(key: key);

  @override
  State<UnitGachaIPadPalette> createState() => _UnitGachaIPadPaletteState();
}

class _UnitGachaIPadPaletteState extends State<UnitGachaIPadPalette> {
  @override
  Widget build(BuildContext context) {
    if (!widget.toolState.isPaletteVisible) {
      // 完全に非表示の場合は小さなボタンで表示
      return _buildMinimizedButton();
    }
    
    return _buildExpandedPalette();
  }

  Widget _buildMinimizedButton() {
    return Positioned(
      right: 20,
      bottom: 20,
      child: GestureDetector(
        onTap: () {
          setState(() {
            widget.toolState.isPaletteVisible = true;
          });
          widget.onStateChanged();
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue[600],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.brush, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildExpandedPalette() {
    final screenSize = MediaQuery.of(context).size;
    final paletteWidth = widget.toolState.isPaletteExpanded ? 600.0 : 56.0;
    final paletteHeight = widget.toolState.isPaletteExpanded ? 120.0 : 56.0;
    
    // 位置が初期化されていない場合はデフォルト位置を設定
    if (widget.toolState.palettePosition == Offset.zero) {
      widget.toolState.palettePosition = Offset(screenSize.width / 2 - paletteWidth / 2, 100);
    }
    
    final maxX = screenSize.width - paletteWidth;
    final clampedX = widget.toolState.palettePosition.dx.clamp(0.0, maxX);
    final clampedY = widget.toolState.palettePosition.dy.clamp(0.0, screenSize.height - paletteHeight);
    
    if (widget.toolState.palettePosition.dx != clampedX || widget.toolState.palettePosition.dy != clampedY) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            widget.toolState.palettePosition = Offset(clampedX, clampedY);
          });
        }
      });
    }
    
    return Positioned(
      left: clampedX,
      bottom: clampedY,
      child: GestureDetector(
        onPanStart: (details) {
          // ドラッグ開始時の処理（必要に応じて追加可能）
        },
        onPanUpdate: (details) {
          setState(() {
            final paletteWidth = widget.toolState.isPaletteExpanded ? 600.0 : 56.0;
            final paletteHeight = widget.toolState.isPaletteExpanded ? 120.0 : 56.0;
            
            final newX = widget.toolState.palettePosition.dx + details.delta.dx;
            final newY = widget.toolState.palettePosition.dy - details.delta.dy;
            final maxX = screenSize.width - paletteWidth;
            
            widget.toolState.palettePosition = Offset(
              newX.clamp(0.0, maxX),
              newY.clamp(0.0, screenSize.height - paletteHeight),
            );
          });
        },
        onPanEnd: (details) {
          widget.toolState.savePalettePosition();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: widget.toolState.isPaletteExpanded ? 600.0 : 56.0,
          height: widget.toolState.isPaletteExpanded ? 120.0 : 56.0,
          padding: EdgeInsets.symmetric(
            horizontal: widget.toolState.isPaletteExpanded ? 12 : 0,
            vertical: widget.toolState.isPaletteExpanded ? 8 : 0,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(widget.toolState.isPaletteExpanded ? 30 : 28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.toolState.isPaletteExpanded
              ? _buildExpandedContent()
              : _buildCollapsedContent(),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Stack(
      children: [
        SizedBox(
          width: 600.0 - 24.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildUndoRedoButtons(),
                  const SizedBox(width: 12),
                  _buildDrawingTools(),
                  const SizedBox(width: 12),
                  _buildAdditionalOptions(),
                ],
              ),
              const SizedBox(height: 8),
              _buildColorPalette(),
            ],
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: _buildMinimizeButton(),
        ),
      ],
    );
  }

  Widget _buildCollapsedContent() {
    return GestureDetector(
      onTap: () {
        setState(() {
          final screenSize = MediaQuery.of(context).size;
          final newWidth = 600.0;
          final currentLeft = widget.toolState.palettePosition.dx;
          final maxLeft = screenSize.width - newWidth;
          widget.toolState.palettePosition = Offset(
            currentLeft.clamp(0.0, maxLeft),
            widget.toolState.palettePosition.dy,
          );
          widget.toolState.isPaletteExpanded = true;
        });
        widget.toolState.savePalettePosition();
        widget.onStateChanged();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: buildToolIcon(widget.toolState.currentTool, size: 28),
      ),
    );
  }

  Widget _buildUndoRedoButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildCircularButton(
          icon: Icons.undo,
          onTap: () {
            // DrawingCanvasでは未実装
          },
          enabled: false,
        ),
        const SizedBox(width: 8),
        _buildCircularButton(
          icon: Icons.redo,
          onTap: () {
            // DrawingCanvasでは未実装
          },
          enabled: false,
        ),
      ],
    );
  }

  Widget _buildDrawingTools() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildToolIconButton(DrawingTool.pen),
        const SizedBox(width: 4),
        _buildToolIconButton(DrawingTool.marker),
        const SizedBox(width: 4),
        _buildToolIconButton(DrawingTool.strokeEraser),
        const SizedBox(width: 4),
        _buildToolIconButton(DrawingTool.partialEraser),
        const SizedBox(width: 4),
        _buildToolIconButton(DrawingTool.lasso),
      ],
    );
  }

  Widget _buildColorPalette() {
    final presetColors = [
      Colors.black,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.red,
      Colors.orange,
      Colors.grey,
      Colors.brown,
    ];
    
    final selectedColor = widget.toolState.currentTool == DrawingTool.marker
        ? widget.toolState.markerBaseColor
        : widget.toolState.currentColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildColorSwatch(selectedColor, isSelected: true),
        const SizedBox(width: 8),
        ...presetColors.map((color) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _buildColorSwatch(color, isSelected: color.value == selectedColor.value),
        )),
      ],
    );
  }

  Widget _buildAdditionalOptions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // スクロールモードボタン
        GestureDetector(
          onTap: () {
            setState(() {
              widget.toolState.isScrollMode = !widget.toolState.isScrollMode;
              if (widget.toolState.isScrollMode) {
                widget.toolState.isEraser = false;
                widget.toolState.currentTool = DrawingTool.pen; // スクロールモード時はペンツールに戻す
              }
            });
            widget.activeToolNotifier.value = widget.toolState.isScrollMode ? 'scroll' : 'pen';
            widget.onStateChanged();
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.toolState.isScrollMode ? Colors.purple[200] : Colors.grey[200],
              border: widget.toolState.isScrollMode ? Border.all(color: Colors.purple[600]!, width: 2) : null,
            ),
            child: Icon(
              Icons.pan_tool,
              color: widget.toolState.isScrollMode ? Colors.purple[800] : Colors.grey[800],
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildCircularButton(
          icon: Icons.more_vert,
          onTap: () {
            _showOptionsMenu();
          },
        ),
      ],
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('指で描画する'),
                    subtitle: const Text('OFF のとき、指ドラッグはスクロール優先になります'),
                    value: widget.toolState.allowFingerDrawing,
                    onChanged: (v) {
                      setState(() {
                        widget.toolState.allowFingerDrawing = v;
                      });
                      setSheetState(() {});
                      widget.onStateChanged();
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMinimizeButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.toolState.isPaletteExpanded = false;
        });
        widget.toolState.savePalettePosition();
        widget.onStateChanged();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[400]!, width: 1),
        ),
        child: Icon(
          Icons.keyboard_arrow_down,
          color: Colors.grey[800],
          size: 20,
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.grey[800] : Colors.grey[400],
          size: 20,
        ),
      ),
    );
  }

  Widget _buildToolIconButton(DrawingTool tool) {
    final isSelected = widget.toolState.currentTool == tool;
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.toolState.changeTool(tool);
        });
        widget.activeToolNotifier.value = widget.toolState.isEraser ? 'eraser' : 'pen';
        widget.onStateChanged();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[300] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: buildToolIcon(tool, size: 24),
      ),
    );
  }

  Widget _buildColorSwatch(Color color, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (widget.toolState.currentTool == DrawingTool.marker) {
            widget.toolState.markerBaseColor = color;
          } else {
            widget.toolState.currentColor = color;
          }
        });
        widget.onStateChanged();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: isSelected
            ? Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

