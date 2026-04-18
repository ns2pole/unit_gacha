// lib/widgets/draggable_scroll_button.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// ドラッグ可能なスクロールボタンウィジェット
class DraggableScrollButton extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const DraggableScrollButton({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<DraggableScrollButton> createState() => _DraggableScrollButtonState();
}

class _DraggableScrollButtonState extends State<DraggableScrollButton> {
  Offset _position = const Offset(184, 100); // 初期位置（AppBarの下に配置）
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
    final savedX = prefs.getDouble('draggable_scroll_button_x');
    final savedY = prefs.getDouble('draggable_scroll_button_y');
    
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
        
        // 画面中央を基準に、スクロールボタンを右側に配置
        final centerX = screenSize.width / 2;
        final centerY = screenSize.height / 2;
        final scrollX = centerX + buttonSize / 2 + spacing;
        final scrollY = centerY - buttonSize / 2;
        
      setState(() {
          _position = Offset(scrollX, scrollY);
      });
      }
    }
  }

  Future<void> _savePosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('draggable_scroll_button_x', _position.dx);
    await prefs.setDouble('draggable_scroll_button_y', _position.dy);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      final screenSize = MediaQuery.of(context).size;
      final isMobile = screenSize.width < 600;
      final buttonSize = isMobile ? 56.0 : 72.0;
      
      final newX = _position.dx + details.delta.dx;
      final newY = _position.dy + details.delta.dy;
      
      // 画面内に制限（ヘッダーエリアも含む）
      _position = Offset(
        newX.clamp(0.0, screenSize.width - buttonSize),
        newY.clamp(0.0, screenSize.height - buttonSize),
      );
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
                color: widget.isSelected ? Colors.purple[600] : Colors.grey[600],
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
                Icons.pan_tool,
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

