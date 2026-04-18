// lib/managers/timer_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/problems/simple_data_manager.dart';

/// タイマーの状態をグローバルに管理するシングルトンクラス
class TimerManager {
  static final TimerManager _instance = TimerManager._internal();
  factory TimerManager() => _instance;
  TimerManager._internal();

  // タイマーの状態
  bool _isTimerEnabled = false;
  bool _isTimerRunning = false;
  int _timerMinutes = 1;
  int _remainingSeconds = 60;
  Timer? _timer;
  String _prefsPrefix = 'integral'; // デフォルト

  // 状態変更を通知するNotifier
  final ValueNotifier<bool> isTimerEnabledNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isTimerRunningNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> remainingSecondsNotifier = ValueNotifier<int>(60);
  final ValueNotifier<bool> canIncrementNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> canDecrementNotifier = ValueNotifier<bool>(true);
  
  // タイマー終了時のコールバック
  VoidCallback? onTimerFinished;

  // ゲッター
  bool get isTimerEnabled => _isTimerEnabled;
  bool get isTimerRunning => _isTimerRunning;
  int get timerMinutes => _timerMinutes;
  int get remainingSeconds => _remainingSeconds;
  String get prefsPrefix => _prefsPrefix;

  /// タイマーの設定を読み込み
  Future<void> loadTimerSettings(String prefsPrefix) async {
    // 既に同じprefsPrefixで初期化済みで、タイマーが実行中の場合は状態を保持
    if (_prefsPrefix == prefsPrefix && _isTimerRunning) {
      return; // 既存の状態を保持
    }
    
    // タイマーが実行中の場合は停止
    if (_isTimerRunning) {
      stopTimer();
    }
    
    _prefsPrefix = prefsPrefix;
    final settings = await SimpleDataManager.getGachaSettings(prefsPrefix);
    _isTimerEnabled = settings['timerEnabled'] as bool? ?? false;
    _timerMinutes = settings['timerMinutes'] as int? ?? 1;
    _remainingSeconds = settings['remainingSeconds'] as int? ?? 60; // デフォルトは1分（60秒）
    _isTimerRunning = settings['timerRunning'] as bool? ?? false;
    
    isTimerEnabledNotifier.value = _isTimerEnabled;
    isTimerRunningNotifier.value = _isTimerRunning;
    remainingSecondsNotifier.value = _remainingSeconds;
    canIncrementNotifier.value = true;
    canDecrementNotifier.value = _remainingSeconds > 30;
    
    if (_isTimerEnabled && _isTimerRunning) {
      startTimer();
    }
  }

  /// タイマー設定を保存
  Future<void> saveTimerSettings() async {
    final settings = await SimpleDataManager.getGachaSettings(_prefsPrefix);
    settings['timerEnabled'] = _isTimerEnabled;
    settings['timerMinutes'] = _timerMinutes;
    settings['remainingSeconds'] = _remainingSeconds;
    settings['timerRunning'] = _isTimerRunning;
    await SimpleDataManager.saveGachaSettings(_prefsPrefix, settings);
  }

  /// タイマーを開始
  void startTimer() {
    _timer?.cancel();
    _isTimerRunning = true;
    isTimerRunningNotifier.value = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        remainingSecondsNotifier.value = _remainingSeconds;
        canDecrementNotifier.value = _remainingSeconds > 30;
      } else {
        timer.cancel();
        _isTimerRunning = false;
        isTimerRunningNotifier.value = false;
        canDecrementNotifier.value = false;
        saveTimerSettings();
        // タイマー終了時のコールバックを呼び出し
        onTimerFinished?.call();
      }
    });
  }

  /// タイマーを停止
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _isTimerRunning = false;
    isTimerRunningNotifier.value = false;
  }

  /// タイマーの表示/非表示トグル
  Future<void> toggleTimerDisplay() async {
    _isTimerEnabled = !_isTimerEnabled;
    isTimerEnabledNotifier.value = _isTimerEnabled;
    if (!_isTimerEnabled) {
      stopTimer();
    }
    await saveTimerSettings();
  }

  /// タイマーの再生/停止
  Future<void> toggleTimerPlayPause() async {
    if (_isTimerRunning) {
      stopTimer();
    } else {
      if (_remainingSeconds > 0) {
        startTimer();
      }
    }
    await saveTimerSettings();
  }

  /// タイマーの時間を増やす（+1分）
  Future<void> incrementTimer60() async {
    _remainingSeconds += 60;
    _timerMinutes = (_remainingSeconds / 60).ceil();
    remainingSecondsNotifier.value = _remainingSeconds;
    canDecrementNotifier.value = _remainingSeconds > 30;
    await saveTimerSettings();
  }

  /// タイマーの時間を増やす（+30秒）
  Future<void> incrementTimer30() async {
    _remainingSeconds += 30;
    _timerMinutes = (_remainingSeconds / 60).ceil();
    remainingSecondsNotifier.value = _remainingSeconds;
    canDecrementNotifier.value = _remainingSeconds > 30;
    await saveTimerSettings();
  }

  /// タイマーの時間を減らす（-1分）
  Future<void> decrementTimer60() async {
    if (_remainingSeconds > 60) {
      _remainingSeconds -= 60;
      _timerMinutes = (_remainingSeconds / 60).ceil();
      remainingSecondsNotifier.value = _remainingSeconds;
      canDecrementNotifier.value = _remainingSeconds > 30;
      await saveTimerSettings();
    }
  }

  /// タイマーの時間を減らす（-30秒）
  Future<void> decrementTimer30() async {
    if (_remainingSeconds > 30) {
      _remainingSeconds -= 30;
      _timerMinutes = (_remainingSeconds / 60).ceil();
      remainingSecondsNotifier.value = _remainingSeconds;
      canDecrementNotifier.value = _remainingSeconds > 30;
      await saveTimerSettings();
    }
  }

  /// タイマーを1分にリセット
  Future<void> resetTimerTo1Minute() async {
    stopTimer();
    _timerMinutes = 1;
    _remainingSeconds = 60;
    remainingSecondsNotifier.value = _remainingSeconds;
    canDecrementNotifier.value = _remainingSeconds > 30;
    await saveTimerSettings();
  }

  /// リソースをクリーンアップ
  void dispose() {
    _timer?.cancel();
    isTimerEnabledNotifier.dispose();
    isTimerRunningNotifier.dispose();
    remainingSecondsNotifier.dispose();
    canIncrementNotifier.dispose();
    canDecrementNotifier.dispose();
  }
}

