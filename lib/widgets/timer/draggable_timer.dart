// lib/widgets/draggable_timer.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../managers/timer_manager.dart';
import 'dart:async';
import '../../localization/app_localizations.dart';

/// ドラッグ可能なコンパクトタイマーウィジェット
class DraggableTimer extends StatefulWidget {
  const DraggableTimer({super.key});

  @override
  State<DraggableTimer> createState() => _DraggableTimerState();
}

class _DraggableTimerState extends State<DraggableTimer> {
  final TimerManager _timerManager = TimerManager();
  Offset _position = const Offset(16, 16); // 初期位置
  bool _isDragging = false;
  Timer? _savePositionTimer;

  @override
  void initState() {
    super.initState();
    _loadPosition();
    // タイマーが有効な場合のみ表示
    _timerManager.isTimerEnabledNotifier.addListener(_updateState);
    _timerManager.isTimerRunningNotifier.addListener(_updateState);
    _timerManager.remainingSecondsNotifier.addListener(_updateState);
    _timerManager.canIncrementNotifier.addListener(_updateState);
    _timerManager.canDecrementNotifier.addListener(_updateState);
  }

  @override
  void dispose() {
    _timerManager.isTimerEnabledNotifier.removeListener(_updateState);
    _timerManager.isTimerRunningNotifier.removeListener(_updateState);
    _timerManager.remainingSecondsNotifier.removeListener(_updateState);
    _timerManager.canIncrementNotifier.removeListener(_updateState);
    _timerManager.canDecrementNotifier.removeListener(_updateState);
    _savePositionTimer?.cancel();
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadPosition() async {
    // SharedPreferencesから位置を読み込む
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble('draggable_timer_x') ?? 16.0;
    final y = prefs.getDouble('draggable_timer_y') ?? 16.0;
    if (mounted) {
      setState(() {
        _position = Offset(x, y);
      });
    }
  }

  Future<void> _savePosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('draggable_timer_x', _position.dx);
    await prefs.setDouble('draggable_timer_y', _position.dy);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      final screenSize = MediaQuery.of(context).size;
      final appBarHeight = AppBar().preferredSize.height;
      final statusBarHeight = MediaQuery.of(context).padding.top;
      final headerHeight = appBarHeight + statusBarHeight;
      
      final newX = _position.dx + details.delta.dx;
      final newY = _position.dy + details.delta.dy;
      
      // 画面内に制限（ヘッダーエリアも含む）
      _position = Offset(
        newX.clamp(0.0, screenSize.width - 180), // タイマーの幅を考慮（ボタン追加で幅が広がる）
        newY.clamp(0.0, screenSize.height - 60), // タイマーの高さを考慮（ヘッダーエリアも含む）
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
    if (!_timerManager.isTimerEnabled) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final minutes = _timerManager.remainingSeconds ~/ 60;
    final seconds = _timerManager.remainingSeconds % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        behavior: HitTestBehavior.translucent, // Allow events to pass through when not dragging
        child: Container(
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade100, Colors.green.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.shade400,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 再生/停止ボタン
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  _timerManager.isTimerRunning ? Icons.pause_circle : Icons.play_circle,
                  size: 20,
                  color: Colors.green[900],
                ),
                onPressed: () => _timerManager.toggleTimerPlayPause(),
              ),
              // 時間調整ボタン（-、30秒削減）
              ValueListenableBuilder<bool>(
                valueListenable: _timerManager.canDecrementNotifier,
                builder: (context, canDecrement, child) {
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle),
                    iconSize: 16,
                    color: canDecrement ? Colors.green[900] : Colors.grey,
                    onPressed: canDecrement ? () => _timerManager.decrementTimer30() : null,
                    tooltip: l10n.timerDecrease30s,
                  );
                },
              ),
              // 時間表示
              Text(
                timeString,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                  decoration: TextDecoration.none,
                ),
              ),
              // 時間調整ボタン（+、30秒追加）
              ValueListenableBuilder<bool>(
                valueListenable: _timerManager.canIncrementNotifier,
                builder: (context, canIncrement, child) {
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle),
                    iconSize: 16,
                    color: canIncrement ? Colors.green[900] : Colors.grey,
                    onPressed: canIncrement ? () => _timerManager.incrementTimer30() : null,
                    tooltip: l10n.timerIncrease30s,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

