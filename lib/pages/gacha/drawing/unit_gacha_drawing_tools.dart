// lib/pages/gacha/unit_gacha_drawing_tools.dart
// 単位ガチャページの描画ツール関連

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ツールタイプのenum
enum DrawingTool {
  pen,           // 太いペン
  marker,        // ハイライター
  strokeEraser,   // ストローク消しゴム（ストローク全体を削除）
  partialEraser,  // 部分消しゴム（部分削除）
  lasso,         // ラッソ選択ツール
}

/// 描画ツールの状態管理
class DrawingToolState {
  DrawingTool currentTool = DrawingTool.pen;
  bool isPaletteExpanded = false;
  bool isPaletteVisible = true;
  Offset palettePosition = Offset.zero;
  Color currentColor = Colors.black;
  Color markerBaseColor = Colors.yellow;
  bool allowFingerDrawing = false; // iPad: 指で描画を許可するか（false=指はスクロール優先）
  double currentStrokeWidth = 2.0;
  bool isEraser = false;
  bool isScrollMode = false;

  /// パレット位置を読み込む
  Future<void> loadPalettePosition(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final savedX = prefs.getDouble('unit_gacha_ipad_palette_x');
    final savedY = prefs.getDouble('unit_gacha_ipad_palette_y');
    final savedExpanded = prefs.getBool('unit_gacha_ipad_palette_expanded');
    final savedVisible = prefs.getBool('unit_gacha_ipad_palette_visible');
    
    final screenSize = MediaQuery.of(context).size;
    
    // まず展開状態を読み込む（位置計算に必要）
    if (savedExpanded != null) {
      isPaletteExpanded = savedExpanded;
    }
    
    final paletteWidth = isPaletteExpanded ? 600.0 : 56.0;
    
    if (savedX != null && savedY != null) {
      palettePosition = Offset(savedX, savedY);
    } else {
      // デフォルト位置（画面下部中央、左上位置ベース）
      palettePosition = Offset(screenSize.width / 2 - paletteWidth / 2, 100);
    }
    
    if (savedVisible != null) {
      isPaletteVisible = savedVisible;
    }
  }

  /// パレット位置を保存
  Future<void> savePalettePosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('unit_gacha_ipad_palette_x', palettePosition.dx);
    await prefs.setDouble('unit_gacha_ipad_palette_y', palettePosition.dy);
    await prefs.setBool('unit_gacha_ipad_palette_expanded', isPaletteExpanded);
    await prefs.setBool('unit_gacha_ipad_palette_visible', isPaletteVisible);
  }

  /// ツールを変更
  void changeTool(DrawingTool tool) {
    currentTool = tool;
    isEraser = tool == DrawingTool.strokeEraser || tool == DrawingTool.partialEraser;
    isScrollMode = false;
    
    // ツールに応じた設定
    switch (tool) {
      case DrawingTool.pen:
        currentStrokeWidth = 2.5;
        currentColor = Colors.black;
        break;
      case DrawingTool.marker:
        // マーカーは「色は markerBaseColor」「不透明度は描画側で固定(0.35)」
        currentStrokeWidth = 16.0;
        break;
      case DrawingTool.strokeEraser:
      case DrawingTool.partialEraser:
        break;
      case DrawingTool.lasso:
        break;
    }
  }
}

/// ツールアイコンを描画するCustomPainter
class ToolIconPainter extends CustomPainter {
  final DrawingTool tool;

  ToolIconPainter({required this.tool});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    switch (tool) {
      case DrawingTool.pen:
        // 太いペン: 太い先端
        paint.color = Colors.white;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.2, size.height * 0.1, size.width * 0.6, size.height * 0.7),
            const Radius.circular(2),
          ),
          paint,
        );
        strokePaint.color = Colors.grey[800]!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.2, size.height * 0.1, size.width * 0.6, size.height * 0.7),
            const Radius.circular(2),
          ),
          strokePaint,
        );
        // 太い線を描画
        paint.color = Colors.grey[800]!;
        canvas.drawLine(
          Offset(size.width * 0.25, size.height * 0.5),
          Offset(size.width * 0.75, size.height * 0.5),
          paint..strokeWidth = 3,
        );
        // 太い先端
        canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.85), 3, paint);
        break;

      case DrawingTool.marker:
        // ハイライター: チャイゼル型の先端、半透明の青い帯
        paint.color = Colors.white;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.2, size.height * 0.1, size.width * 0.6, size.height * 0.7),
            const Radius.circular(2),
          ),
          paint,
        );
        strokePaint.color = Colors.grey[800]!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.2, size.height * 0.1, size.width * 0.6, size.height * 0.7),
            const Radius.circular(2),
          ),
          strokePaint,
        );
        // 青い帯
        paint.color = Colors.blue.withOpacity(0.3);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.25, size.height * 0.3, size.width * 0.5, size.height * 0.3),
            const Radius.circular(1),
          ),
          paint,
        );
        // チャイゼル型の先端
        final path = Path();
        path.moveTo(size.width * 0.3, size.height * 0.85);
        path.lineTo(size.width * 0.7, size.height * 0.85);
        path.lineTo(size.width * 0.65, size.height * 0.95);
        path.lineTo(size.width * 0.35, size.height * 0.95);
        path.close();
        paint.color = Colors.blue[300]!.withOpacity(0.5);
        canvas.drawPath(path, paint);
        break;

      case DrawingTool.strokeEraser:
        // ストローク消しゴム: ピンクの先端
        paint.color = Colors.white;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.2, size.height * 0.1, size.width * 0.6, size.height * 0.7),
            const Radius.circular(2),
          ),
          paint,
        );
        strokePaint.color = Colors.grey[800]!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.2, size.height * 0.1, size.width * 0.6, size.height * 0.7),
            const Radius.circular(2),
          ),
          strokePaint,
        );
        // ピンクの先端
        paint.color = Colors.pink[300]!;
        canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.85), 4, paint);
        break;

      case DrawingTool.partialEraser:
        // 部分消しゴム: 斜めのストライプパターン
        paint.color = Colors.white;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.2, size.height * 0.1, size.width * 0.6, size.height * 0.7),
            const Radius.circular(2),
          ),
          paint,
        );
        strokePaint.color = Colors.grey[800]!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.2, size.height * 0.1, size.width * 0.6, size.height * 0.7),
            const Radius.circular(2),
          ),
          strokePaint,
        );
        // 斜めのストライプ
        strokePaint.color = Colors.grey[400]!;
        strokePaint.strokeWidth = 1;
        for (int i = 0; i < 5; i++) {
          final y = size.height * 0.2 + (i * size.height * 0.15);
          canvas.drawLine(
            Offset(size.width * 0.25, y),
            Offset(size.width * 0.75, y + size.height * 0.2),
            strokePaint,
          );
        }
        break;

      case DrawingTool.lasso:
        // ラッソ選択ツール: 輪っかのアイコン
        paint.color = Colors.white;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.2, size.height * 0.1, size.width * 0.6, size.height * 0.7),
            const Radius.circular(2),
          ),
          paint,
        );
        strokePaint.color = Colors.grey[800]!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.2, size.height * 0.1, size.width * 0.6, size.height * 0.7),
            const Radius.circular(2),
          ),
          strokePaint,
        );
        // 輪っかのパス
        strokePaint.color = Colors.blue[600]!;
        strokePaint.strokeWidth = 2;
        final lassoPath = Path();
        lassoPath.moveTo(size.width * 0.3, size.height * 0.3);
        lassoPath.quadraticBezierTo(size.width * 0.5, size.height * 0.2, size.width * 0.7, size.height * 0.3);
        lassoPath.quadraticBezierTo(size.width * 0.8, size.height * 0.5, size.width * 0.7, size.height * 0.7);
        lassoPath.quadraticBezierTo(size.width * 0.5, size.height * 0.8, size.width * 0.3, size.height * 0.7);
        lassoPath.quadraticBezierTo(size.width * 0.2, size.height * 0.5, size.width * 0.3, size.height * 0.3);
        canvas.drawPath(lassoPath, strokePaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ツールアイコンを描画
Widget buildToolIcon(DrawingTool tool, {double size = 24}) {
  return CustomPaint(
    size: Size(size, size),
    painter: ToolIconPainter(tool: tool),
  );
}

