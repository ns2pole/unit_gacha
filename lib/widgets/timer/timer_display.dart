// lib/widgets/timer_display.dart
import 'package:flutter/material.dart';
import '../../managers/timer_manager.dart';
import '../../localization/app_localizations.dart';

/// タイマー表示ウィジェット（共通化）
class TimerDisplay extends StatelessWidget {
  final TimerManager timerManager;
  final FocusNode? focusNode;

  const TimerDisplay({
    super.key,
    required this.timerManager,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: timerManager.isTimerEnabledNotifier,
      builder: (context, isEnabled, child) {
        if (!isEnabled) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<int>(
          valueListenable: timerManager.remainingSecondsNotifier,
          builder: (context, remainingSeconds, child) {
            final minutes = remainingSeconds ~/ 60;
            final seconds = remainingSeconds % 60;
            final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

            return ValueListenableBuilder<bool>(
              valueListenable: timerManager.isTimerRunningNotifier,
              builder: (context, isRunning, child) {
                return _TimerContent(
                  timeString: timeString,
                  isRunning: isRunning,
                  timerManager: timerManager,
                  focusNode: focusNode,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _TimerContent extends StatelessWidget {
  final String timeString;
  final bool isRunning;
  final TimerManager timerManager;
  final FocusNode? focusNode;

  const _TimerContent({
    required this.timeString,
    required this.isRunning,
    required this.timerManager,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.green.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.shade400,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 再生/停止ボタン
            IconButton(
              focusNode: focusNode,
              icon: Icon(isRunning ? Icons.pause_circle : Icons.play_circle),
              onPressed: () => timerManager.toggleTimerPlayPause(),
              iconSize: 32,
              color: Colors.green[900],
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
            // 時間調整ボタン（-、30秒削減）
            ValueListenableBuilder<bool>(
              valueListenable: timerManager.canDecrementNotifier,
              builder: (context, canDecrement, child) {
                return IconButton(
                  focusNode: focusNode,
                  icon: const Icon(Icons.remove_circle),
                  onPressed: canDecrement ? () => timerManager.decrementTimer30() : null,
                  iconSize: 24,
                  color: canDecrement ? Colors.green[900] : Colors.grey,
                  tooltip: l10n.timerDecrease30s,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
            // 時間表示
            Text(
              timeString,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
              ),
            ),
            // 時間調整ボタン（+、30秒追加）
            ValueListenableBuilder<bool>(
              valueListenable: timerManager.canIncrementNotifier,
              builder: (context, canIncrement, child) {
                return IconButton(
                  focusNode: focusNode,
                  icon: const Icon(Icons.add_circle),
                  onPressed: canIncrement ? () => timerManager.incrementTimer30() : null,
                  iconSize: 24,
                  color: canIncrement ? Colors.green[900] : Colors.grey,
                  tooltip: l10n.timerIncrease30s,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
            // 更新ボタン（1分にリセット）
            IconButton(
              focusNode: focusNode,
              icon: const Icon(Icons.refresh),
              onPressed: () => timerManager.resetTimerTo1Minute(),
              iconSize: 24,
              color: Colors.green[900],
              tooltip: l10n.timerResetTo1m,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}



