// lib/widgets/timer_toggle.dart
import 'package:flutter/material.dart';
import '../../managers/timer_manager.dart';

/// タイマートグルボタン（共通化）
class TimerToggle extends StatelessWidget {
  final TimerManager timerManager;

  const TimerToggle({
    super.key,
    required this.timerManager,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: timerManager.isTimerEnabledNotifier,
      builder: (context, isEnabled, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              timerManager.toggleTimerDisplay();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEnabled ? Colors.orange.shade100 : Colors.grey.shade200,
                border: Border.all(
                  color: isEnabled ? Colors.orange.shade400 : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.timer,
                size: 28,
                color: isEnabled ? Colors.orange.shade700 : Colors.grey.shade600,
              ),
            ),
          ),
        );
      },
    );
  }
}

