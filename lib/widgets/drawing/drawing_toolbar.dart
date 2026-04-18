// lib/widgets/drawing_toolbar.dart
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../../localization/app_localizations.dart';

/// 描画ツールバーのウィジェット
class DrawingToolbar extends StatefulWidget {
  final bool isEraser;
  final bool isScrollMode;
  final Color currentColor;
  final double currentStrokeWidth;
  final VoidCallback onPenModeChanged;
  final ValueChanged<bool> onEraserChanged;
  final ValueChanged<bool> onScrollModeChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;

  const DrawingToolbar({
    super.key,
    required this.isEraser,
    required this.isScrollMode,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.onPenModeChanged,
    required this.onEraserChanged,
    required this.onScrollModeChanged,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
  });

  @override
  State<DrawingToolbar> createState() => _DrawingToolbarState();
}

class _DrawingToolbarState extends State<DrawingToolbar> {
  bool _isPenPaletteExpanded = false;

  @override
  Widget build(BuildContext context) {
    final penSelected = !widget.isEraser && !widget.isScrollMode;
    final eraserSelected = widget.isEraser && !widget.isScrollMode;
    final scrollSelected = widget.isScrollMode;

    // パレットが展開されている場合は、背景をタップして閉じられるようにする
    if (_isPenPaletteExpanded) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          // 背景をタップして閉じる（全画面をカバー、ただしパレットとボタンの下に配置）
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() {
                  _isPenPaletteExpanded = false;
                });
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          // ボタンとパレット（背景のGestureDetectorより上に配置、ただしボタンは最前面）
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ペン系パレットボタン
              _buildPaletteButton(
                icon: Icons.edit,
                isSelected: penSelected,
                isExpanded: _isPenPaletteExpanded,
                onTap: () {
                  setState(() {
                    _isPenPaletteExpanded = !_isPenPaletteExpanded;
                  });
                },
                child: _isPenPaletteExpanded
                    ? _buildPenPalette(penSelected)
                    : null,
              ),
              const SizedBox(width: 8),
              // 消しゴムボタン（単独、最前面に配置）
              Material(
                elevation: 20, // パレットより高いelevation
                shape: const CircleBorder(),
                child: _buildSimpleButton(
                  icon: Icons.auto_fix_high,
                  isSelected: eraserSelected,
                  onTap: () {
                    widget.onEraserChanged(!eraserSelected);
                  },
                ),
              ),
              const SizedBox(width: 8),
              // スクロールボタン（単独、最前面に配置）
              Material(
                elevation: 20, // パレットより高いelevation
                shape: const CircleBorder(),
                child: _buildSimpleButton(
                  icon: Icons.pan_tool,
                  isSelected: scrollSelected,
                  onTap: () {
                    widget.onScrollModeChanged(!scrollSelected);
                  },
                ),
              ),
            ],
          ),
        ],
      );
    }

    // パレットが閉じている場合は、通常のRowを返す
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ペン系パレットボタン
        _buildPaletteButton(
          icon: Icons.edit,
          isSelected: penSelected,
          isExpanded: _isPenPaletteExpanded,
          onTap: () {
            setState(() {
              _isPenPaletteExpanded = !_isPenPaletteExpanded;
            });
          },
          child: _isPenPaletteExpanded ? _buildPenPalette(penSelected) : null,
        ),
        const SizedBox(width: 8),
        // 消しゴムボタン（単独）
        _buildSimpleButton(
          icon: Icons.auto_fix_high,
          isSelected: eraserSelected,
          onTap: () {
            widget.onEraserChanged(!eraserSelected);
          },
        ),
        const SizedBox(width: 8),
        // スクロールボタン（単独）
        _buildSimpleButton(
          icon: Icons.pan_tool,
          isSelected: scrollSelected,
          onTap: () {
            widget.onScrollModeChanged(!scrollSelected);
          },
        ),
      ],
    );
  }

  Widget _buildPaletteButton({
    required IconData icon,
    required bool isSelected,
    required bool isExpanded,
    required VoidCallback onTap,
    Widget? child,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 円形ボタン（最前面に配置）
        Material(
          elevation: 20, // パレットより高いelevation
          shape: const CircleBorder(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected ? Colors.green[600] : Colors.grey[600],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ),
        ),
        // 展開されたパレット（ボタンの下に表示、ボタンより低いelevation）
        if (child != null)
          Positioned(
            top: 72, // ボタンの下に配置（64 + 8）
            right: 0,
            child: Material(
              elevation: 16, // ボタンより低いelevation
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // パレット外側（パレット自体の外側）をタップした時に閉じる
                  // パレット内のタップは無視（子要素が処理）
                },
                child: child,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSimpleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // アイコンに基づいて色を決定
    Color selectedColor;
    if (icon == Icons.auto_fix_high) {
      // 消しゴムボタン
      selectedColor = Colors.brown[600]!;
    } else if (icon == Icons.pan_tool) {
      // スクロールボタン
      selectedColor = Colors.purple[600]!;
    } else {
      // デフォルト（緑）
      selectedColor = Colors.green[600]!;
    }
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.grey[600],
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildPenPalette(bool penSelected) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ペンモードボタン
          _buildPaletteItem(
            icon: Icons.edit,
            label: l10n.drawingPen,
            isSelected: penSelected,
            onTap: () {
              setState(() {
                _isPenPaletteExpanded = false;
              });
              widget.onPenModeChanged();
            },
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          // 色選択
          Text(
            l10n.drawingColor,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.availableColors.map((color) {
              return _buildColorButton(color);
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          // 線の太さ
          Text(
            l10n.drawingThickness,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.strokeWidths.map((width) {
              return _buildStrokeWidthButton(width);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue[700] : Colors.grey[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.blue[700] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = widget.currentColor == color && !widget.isEraser;
    return GestureDetector(
      onTap: () {
        widget.onEraserChanged(false);
        widget.onColorChanged(color);
      },
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
    );
  }

  Widget _buildStrokeWidthButton(double width) {
    final isSelected = widget.currentStrokeWidth == width;
    return GestureDetector(
      onTap: () => widget.onStrokeWidthChanged(width),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.grey[100],
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Container(
            width: width * 2,
            height: width * 2,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
