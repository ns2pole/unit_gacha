// lib/utils/app_logger.dart
import 'package:flutter/foundation.dart';

/// アプリケーションログを整理して出力するユーティリティ
class AppLogger {
  static const String _successPrefix = '✅ [SUCCESS]';
  static const String _warningPrefix = '⚠️  [WARNING]';
  static const String _errorPrefix = '❌ [ERROR]';
  static const String _infoPrefix = 'ℹ️  [INFO]';
  static const String _debugPrefix = '🔍 [DEBUG]';

  // セクション/サブセクションのカウンター
  static int _sectionCounter = 0;
  static int _totalSections = 0;

  /// セクションカウンターをリセット（初期化開始時に呼び出す）
  static void resetSectionCounter({int totalSections = 0}) {
    _sectionCounter = 0;
    _totalSections = totalSections;
  }

  /// セクション区切りを出力
  static void section(String sectionName, {bool showNumber = false}) {
    if (kDebugMode) {
      if (showNumber) {
        _sectionCounter++;
      }
      print('');
      print('═' * 60);
      if (showNumber && _totalSections > 0) {
        print('  $_sectionCounter/$_totalSections $sectionName');
      } else {
        print('  $sectionName');
      }
      print('═' * 60);
    }
  }

  /// 成功ログを出力
  static void success(String message, {String? details}) {
    if (kDebugMode) {
      print('$_successPrefix $message');
      if (details != null) {
        print('    $details');
      }
    }
  }

  /// 警告ログを出力
  static void warning(String message, {String? details}) {
    if (kDebugMode) {
      print('$_warningPrefix $message');
      if (details != null) {
        print('    $details');
      }
    }
  }

  /// エラーログを出力
  static void error(String message, {Object? error, String? details}) {
    if (kDebugMode) {
      print('$_errorPrefix $message');
      if (error != null) {
        print('    エラー: $error');
      }
      if (details != null) {
        print('    $details');
      }
    }
  }

  /// 情報ログを出力
  static void info(String message, {String? details}) {
    if (kDebugMode) {
      print('$_infoPrefix $message');
      if (details != null) {
        print('    $details');
      }
    }
  }

  /// デバッグログを出力（詳細なデバッグ情報用）
  static void debug(String message, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      print('$_debugPrefix $message');
      if (data != null) {
        data.forEach((key, value) {
          print('    $key: $value');
        });
      }
    }
  }

  /// Firestore操作のデバッグログ（認証状態を含む）
  static void firestoreOperation(String operation, String userId, {
    bool showAuthDetails = false,
  }) {
    if (kDebugMode && showAuthDetails) {
      // 認証状態の詳細は必要に応じて表示
      debug('Firestore操作: $operation', data: {
        'ユーザーID': userId,
      });
    }
  }

  /// サブセクション区切りを出力
  static void subsection(String subsectionName, {bool showNumber = true}) {
    if (kDebugMode) {
      if (showNumber) {
        _sectionCounter++;
      }
      print('');
      print('─' * 60);
      if (showNumber && _totalSections > 0) {
        print('  $_sectionCounter/$_totalSections $subsectionName');
      } else {
        print('  $subsectionName');
      }
      print('─' * 60);
    }
  }
}
