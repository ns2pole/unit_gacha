// lib/utils/progress_update_mixin.dart
import 'package:flutter/material.dart';

/// 達成率表示を更新するためのミックスイン
/// home_page.dartとbonus_gacha_page.dartで共通使用
mixin ProgressUpdateMixin<T extends StatefulWidget> on State<T> {
  int _progressUpdateKey = 0;

  /// 達成率更新キーを取得
  int get progressUpdateKey => _progressUpdateKey;

  /// 達成率を更新する（ページが再表示される時やガチャから戻ってきた時に呼ばれる）
  void updateProgress() {
    if (mounted) {
      setState(() {
        _progressUpdateKey++;
      });
    }
  }

  /// 達成率表示用のValueKeyを生成
  ValueKey<String> buildProgressKey({
    required String prefsPrefix,
    required bool showProgress,
  }) {
    return ValueKey('progress_${prefsPrefix}_${showProgress}_${_progressUpdateKey}');
  }
}

