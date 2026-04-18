// lib/widgets/draggable_calculator_button.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// ドラッグ可能な電卓ボタンウィジェット
class DraggableCalculatorButton extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onTap;
  final bool isDraggable; // ドラッグ可能かどうか

  const DraggableCalculatorButton({
    super.key,
    required this.isExpanded,
    required this.onTap,
    this.isDraggable = true, // デフォルトはドラッグ可能
  });

  @override
  State<DraggableCalculatorButton> createState() => _DraggableCalculatorButtonState();
}

class _DraggableCalculatorButtonState extends State<DraggableCalculatorButton> {
  Offset _position = const Offset(0, 0);
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
    // ドラッグ不可の場合は常に右下に固定
    if (!widget.isDraggable) {
      if (mounted) {
        final screenSize = MediaQuery.of(context).size;
        final safeArea = MediaQuery.of(context).padding;
        final isMobile = screenSize.width < 600;
        final buttonSize = isMobile ? 56.0 : 72.0;
        // SafeAreaとマージンを考慮して、より内側に配置
        final marginX = isMobile ? 24.0 : 32.0; // 右端からのマージン
        final marginY = isMobile ? 80.0 : 100.0; // 下端からのマージン（上に配置するため大きめに設定）
        
        // 画面右下（SafeAreaとマージンを考慮した位置）
        final rightX = screenSize.width - buttonSize - marginX - safeArea.right;
        final bottomY = screenSize.height - buttonSize - marginY - safeArea.bottom;
        
        setState(() {
          _position = Offset(rightX, bottomY);
        });
      }
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final savedX = prefs.getDouble('draggable_calculator_button_x');
    final savedY = prefs.getDouble('draggable_calculator_button_y');
    
    if (mounted) {
      if (savedX != null && savedY != null) {
        // 保存された位置がある場合はそれを使用
        setState(() {
          _position = Offset(savedX, savedY);
        });
      } else {
        // 保存された位置がない場合は画面右下に配置
        final screenSize = MediaQuery.of(context).size;
        final safeArea = MediaQuery.of(context).padding;
        final isMobile = screenSize.width < 600;
        final buttonSize = isMobile ? 56.0 : 72.0;
        // SafeAreaとマージンを考慮して、より内側に配置
        final margin = isMobile ? 24.0 : 32.0; // 右端と下端からのマージン（大きめに設定）
        
        // 画面右下（SafeAreaとマージンを考慮した位置）
        final rightX = screenSize.width - buttonSize - margin - safeArea.right;
        final bottomY = screenSize.height - buttonSize - margin - safeArea.bottom;
        
        setState(() {
          _position = Offset(rightX, bottomY);
        });
        _savePosition();
      }
    }
  }

  Future<void> _savePosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('draggable_calculator_button_x', _position.dx);
    await prefs.setDouble('draggable_calculator_button_y', _position.dy);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // ドラッグ不可の場合は何もしない
    if (!widget.isDraggable) return;
    
    setState(() {
      // 領域制限を撤廃：自由に移動可能
      _position = _position + details.delta;
    });
    
    // デバウンスして位置を保存
    _savePositionTimer?.cancel();
    _savePositionTimer = Timer(const Duration(milliseconds: 500), _savePosition);
  }

  void _onPanEnd(DragEndDetails details) {
    // ドラッグ不可の場合は何もしない
    if (!widget.isDraggable) return;
    
    setState(() {
      _isDragging = false;
    });
    _savePosition();
  }

  void _onPanStart(DragStartDetails details) {
    // ドラッグ不可の場合は何もしない
    if (!widget.isDraggable) return;
    
    setState(() {
      _isDragging = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: widget.isDraggable
          ? GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: _buildButton(),
            )
          : _buildButton(),
    );
  }
  
  Widget _buildButton() {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final buttonSize = isMobile ? 56.0 : 72.0;
    final iconSize = isMobile ? 28.0 : 36.0;
    
    return Material(
      elevation: 20,
      shape: const CircleBorder(),
      child: InkWell(
        borderRadius: BorderRadius.circular(buttonSize / 2),
        onTap: widget.onTap,
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: widget.isExpanded ? Colors.blue[600] : Colors.grey[600],
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
            widget.isExpanded ? Icons.keyboard_arrow_up : Icons.calculate,
            color: Colors.white,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}








