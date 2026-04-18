// lib/widgets/draggable_eraser_button.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// ドラッグ可能な消しゴムボタンウィジェット
class DraggableEraserButton extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const DraggableEraserButton({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<DraggableEraserButton> createState() => _DraggableEraserButtonState();
}

class _DraggableEraserButtonState extends State<DraggableEraserButton> {
  Offset _position = const Offset(100, 100); // 初期位置（AppBarの下に配置）
  bool _isDragging = false;
  Timer? _savePositionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPosition();
    });
  }

  @override
  void dispose() {
    _savePositionTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final savedX = prefs.getDouble('draggable_eraser_button_x');
    final savedY = prefs.getDouble('draggable_eraser_button_y');
    
    if (mounted) {
      if (savedX != null && savedY != null) {
        // 保存された位置がある場合はそれを使用
        setState(() {
          _position = Offset(savedX, savedY);
        });
      } else {
        // 保存された位置がない場合は画面中央に配置
        final screenSize = MediaQuery.of(context).size;
        final isMobile = screenSize.width < 600;
        final buttonSize = isMobile ? 56.0 : 72.0;
        final spacing = isMobile ? 40.0 : 60.0;
        
        // 画面中央を基準に、消しゴムボタンを中央に配置
        final centerX = screenSize.width / 2;
        final centerY = screenSize.height / 2;
        final eraserX = centerX - buttonSize / 2;
        final eraserY = centerY - buttonSize / 2;
        
      setState(() {
          _position = Offset(eraserX, eraserY);
      });
      }
    }
  }

  Future<void> _savePosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('draggable_eraser_button_x', _position.dx);
    await prefs.setDouble('draggable_eraser_button_y', _position.dy);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      // 領域制限を撤廃：自由に移動可能
      _position = _position + details.delta;
    });
    
    // デバウンスして位置を保存
    _savePositionTimer?.cancel();
    _savePositionTimer = Timer(const Duration(milliseconds: 500), _savePosition);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    _savePosition();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final buttonSize = isMobile ? 56.0 : 72.0;
    final iconSize = isMobile ? 28.0 : 36.0;
    
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Material(
          elevation: 20,
          shape: const CircleBorder(),
          child: InkWell(
            borderRadius: BorderRadius.circular(buttonSize / 2),
            onTap: widget.onTap,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: widget.isSelected ? Colors.orange[600] : Colors.grey[600],
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
                Icons.auto_fix_high,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

