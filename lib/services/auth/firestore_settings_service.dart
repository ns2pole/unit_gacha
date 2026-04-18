// lib/services/firestore_settings_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_auth_service.dart';
import '../../managers/app_logger.dart';

/// Firestore設定サービス
/// ガチャ設定、ユーザー設定、その他の設定をFirestoreに保存/取得
class FirestoreSettingsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 認証状態をログに記録（デバッグ用）
  static void _logAuthStatus(String userId, String operation, {bool isError = false}) {
    final isAuthenticated = FirebaseAuthService.isAuthenticated;
    final currentUserId = FirebaseAuthService.userId;
    final authMatches = currentUserId == userId;
    
    if (isError) {
      AppLogger.debug('Firestore操作: $operation (エラー発生)', data: {
        'リクエストユーザーID': userId,
        '認証状態': isAuthenticated,
        '現在のユーザーID': currentUserId ?? 'null',
        '認証一致': authMatches,
      });
      
      if (!isAuthenticated) {
        AppLogger.warning('ユーザーが認証されていません');
      } else if (!authMatches) {
        AppLogger.warning('リクエストユーザーIDと現在の認証ユーザーIDが一致しません');
      }
    }
  }

  /// ユーザーの設定コレクションへの参照を取得
  static DocumentReference _getUserSettingsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('user_settings');
  }

  /// ガチャ設定コレクションへの参照を取得
  static CollectionReference _getGachaSettingsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('gacha_settings')
        .collection('gacha_types');
  }

  /// その他の設定コレクションへの参照を取得
  static CollectionReference _getOtherSettingsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('other_settings')
        .collection('keys');
  }

  /// キーをFirestoreのドキュメントIDとして使用できるようにエンコード
  /// スラッシュなどの特殊文字を含むキーを安全にエンコード
  static String _encodeKey(String key) {
    // URLエンコードを使用してスラッシュなどの特殊文字をエンコード
    return Uri.encodeComponent(key);
  }

  /// エンコードされたキーを元のキーにデコード
  static String _decodeKey(String encodedKey) {
    try {
      return Uri.decodeComponent(encodedKey);
    } catch (e) {
      // デコードに失敗した場合は元のキーを返す（後方互換性のため）
      return encodedKey;
    }
  }

  // ============================================================================
  // ガチャ設定
  // ============================================================================

  /// ガチャ設定を保存
  static Future<bool> saveGachaSettings({
    required String userId,
    required String gachaType,
    required Map<String, dynamic> settings,
  }) async {
    try {
      final settingsRef = _getGachaSettingsRef(userId).doc(gachaType);
      
      await settingsRef.set({
        'gachaType': gachaType,
        'settings': settings,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AppLogger.success('ガチャ設定を保存しました', details: 'gachaType: $gachaType');
      return true;
    } catch (e) {
      AppLogger.error('ガチャ設定の保存に失敗しました', error: e, details: 'gachaType: $gachaType');
      return false;
    }
  }

  /// ガチャ設定を取得
  static Future<Map<String, dynamic>?> getGachaSettings({
    required String userId,
    required String gachaType,
  }) async {
    try {
      final settingsDoc = await _getGachaSettingsRef(userId)
          .doc(gachaType)
          .get();

      if (!settingsDoc.exists) {
        return null;
      }

      final data = settingsDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        return null;
      }

      // Timestampを文字列に変換
      final lastUpdated = data['lastUpdated'];
      if (lastUpdated is Timestamp) {
        data['lastUpdated'] = lastUpdated.toDate().toIso8601String();
      }

      final settings = data['settings'] as Map<String, dynamic>?;
      if (settings != null) {
        settings['lastUpdated'] = data['lastUpdated'];
      }

      return settings;
    } catch (e) {
      AppLogger.error('ガチャ設定の取得に失敗しました', error: e, details: 'gachaType: $gachaType');
      return null;
    }
  }

  /// 全ガチャ設定を取得
  static Future<Map<String, Map<String, dynamic>>> getAllGachaSettings({
    required String userId,
  }) async {
    try {
      final snapshot = await _getGachaSettingsRef(userId).get();
      
      final Map<String, Map<String, dynamic>> settings = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        
        // Timestampを文字列に変換
        final lastUpdated = data['lastUpdated'];
        String? lastUpdatedString;
        if (lastUpdated is Timestamp) {
          lastUpdatedString = lastUpdated.toDate().toIso8601String();
        } else if (lastUpdated is String) {
          lastUpdatedString = lastUpdated;
        }
        
        final settingsData = data['settings'] as Map<String, dynamic>?;
        if (settingsData != null) {
          settingsData['lastUpdated'] = lastUpdatedString;
          settings[doc.id] = settingsData;
        }
      }
      
      AppLogger.success('全ガチャ設定を取得しました', details: '${settings.length}件の設定を取得');
      return settings;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') || errorStr.contains('permission-denied')) {
        AppLogger.warning('全ガチャ設定の取得が権限エラーで失敗しました', 
          details: 'Firestoreセキュリティルールを確認してください。FIRESTORE_SECURITY_RULES.mdを参照してください。');
        _logAuthStatus(userId, 'getAllGachaSettings', isError: true);
      } else {
        AppLogger.error('全ガチャ設定の取得に失敗しました', error: e);
      }
      return {};
    }
  }

  // ============================================================================
  // ユーザー設定
  // ============================================================================

  /// ユーザー設定を保存
  static Future<bool> saveUserSettings({
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      final settingsRef = _getUserSettingsRef(userId);
      
      await settingsRef.set({
        'settings': settings,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AppLogger.success('ユーザー設定を保存しました');
      return true;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') || errorStr.contains('permission-denied')) {
        AppLogger.warning('ユーザー設定の保存が権限エラーで失敗しました',
          details: 'Firestoreセキュリティルールを確認してください。FIRESTORE_SECURITY_RULES.mdを参照してください。');
        _logAuthStatus(userId, 'saveUserSettings', isError: true);
      } else {
        AppLogger.error('ユーザー設定の保存に失敗しました', error: e);
      }
      return false;
    }
  }

  /// ユーザー設定を取得
  static Future<Map<String, dynamic>?> getUserSettings({
    required String userId,
  }) async {
    try {
      final settingsDoc = await _getUserSettingsRef(userId).get();

      if (!settingsDoc.exists) {
        return null;
      }

      final data = settingsDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        return null;
      }

      // Timestampを文字列に変換
      final lastUpdated = data['lastUpdated'];
      String? lastUpdatedString;
      if (lastUpdated is Timestamp) {
        lastUpdatedString = lastUpdated.toDate().toIso8601String();
      } else if (lastUpdated is String) {
        lastUpdatedString = lastUpdated;
      }

      final settings = data['settings'] as Map<String, dynamic>?;
      if (settings != null) {
        settings['lastUpdated'] = lastUpdatedString;
      }

      AppLogger.success('ユーザー設定を取得しました');
      return settings;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') || errorStr.contains('permission-denied')) {
        AppLogger.warning('ユーザー設定の取得が権限エラーで失敗しました',
          details: 'Firestoreセキュリティルールを確認してください。FIRESTORE_SECURITY_RULES.mdを参照してください。');
        _logAuthStatus(userId, 'getUserSettings', isError: true);
      } else {
        AppLogger.error('ユーザー設定の取得に失敗しました', error: e);
      }
      return null;
    }
  }

  // ============================================================================
  // その他の設定（SharedPreferencesの個別キー）
  // ============================================================================

  /// その他の設定を保存
  static Future<bool> saveOtherSetting({
    required String userId,
    required String key,
    required dynamic value,
  }) async {
    try {
      // キーをエンコードしてFirestoreのドキュメントIDとして使用
      final encodedKey = _encodeKey(key);
      final settingRef = _getOtherSettingsRef(userId).doc(encodedKey);
      
      await settingRef.set({
        'key': key, // 元のキーも保存（後方互換性のため）
        'value': value,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AppLogger.success('その他の設定を保存しました', details: 'key: $key');
      return true;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') || errorStr.contains('permission-denied')) {
        AppLogger.warning('その他の設定の保存が権限エラーで失敗しました',
          details: 'key: $key - Firestoreセキュリティルールを確認してください。FIRESTORE_SECURITY_RULES.mdを参照してください。');
        _logAuthStatus(userId, 'saveOtherSetting', isError: true);
      } else {
        AppLogger.error('その他の設定の保存に失敗しました', error: e, details: 'key: $key');
      }
      return false;
    }
  }

  /// その他の設定を取得
  static Future<dynamic> getOtherSetting({
    required String userId,
    required String key,
  }) async {
    try {
      // キーをエンコードしてFirestoreのドキュメントIDとして使用
      final encodedKey = _encodeKey(key);
      final settingDoc = await _getOtherSettingsRef(userId).doc(encodedKey).get();

      if (!settingDoc.exists) {
        return null;
      }

      final data = settingDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        return null;
      }

      return data['value'];
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') || errorStr.contains('permission-denied')) {
        AppLogger.warning('その他の設定の取得が権限エラーで失敗しました',
          details: 'key: $key - Firestoreセキュリティルールを確認してください。FIRESTORE_SECURITY_RULES.mdを参照してください。');
        _logAuthStatus(userId, 'getOtherSetting', isError: true);
      } else {
        AppLogger.error('その他の設定の取得に失敗しました', error: e, details: 'key: $key');
      }
      return null;
    }
  }

  /// 全その他の設定を取得
  static Future<Map<String, dynamic>> getAllOtherSettings({
    required String userId,
  }) async {
    try {
      final snapshot = await _getOtherSettingsRef(userId).get();
      
      final Map<String, dynamic> settings = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        
        // ドキュメントIDをデコードして元のキーに戻す
        // 後方互換性のため、data['key']が存在する場合はそれを使用
        final originalKey = data['key'] as String? ?? _decodeKey(doc.id);
        settings[originalKey] = data['value'];
      }
      
      AppLogger.success('全その他の設定を取得しました', details: '${settings.length}件の設定を取得');
      return settings;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') || errorStr.contains('permission-denied')) {
        AppLogger.warning('全その他の設定の取得が権限エラーで失敗しました',
          details: 'Firestoreセキュリティルールを確認してください。FIRESTORE_SECURITY_RULES.mdを参照してください。');
        _logAuthStatus(userId, 'getAllOtherSettings', isError: true);
      } else {
        AppLogger.error('全その他の設定の取得に失敗しました', error: e);
      }
      return {};
    }
  }

  // ============================================================================
  // 全設定の取得（初期同期用）
  // ============================================================================

  /// 全設定を取得（初期同期用）
  static Future<Map<String, dynamic>> getAllSettings({
    required String userId,
  }) async {
    try {
      // タイムアウトを追加してフリーズを防ぐ
      final results = await Future.wait([
        getAllGachaSettings(userId: userId),
        getUserSettings(userId: userId),
        getAllOtherSettings(userId: userId),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          AppLogger.warning('全設定の取得がタイムアウトしました', details: '10秒以内に完了しませんでした');
          return [
            <String, Map<String, dynamic>>{},
            null,
            <String, dynamic>{},
          ];
        },
      );

      // 権限エラーをチェック（空の結果が返された場合は権限エラーの可能性）
      final hasPermissionError = results.every((result) => 
        result == null || 
        (result is Map && result.isEmpty)
      );

      if (hasPermissionError) {
        AppLogger.warning('全設定の取得で権限エラーが検出されました', 
          details: 'Firestoreセキュリティルールを確認してください。FIRESTORE_SECURITY_RULES.mdを参照してください。');
        return {};
      }

      AppLogger.success('全設定を取得しました');
      return {
        'gacha_settings': results[0] as Map<String, Map<String, dynamic>>,
        'user_settings': results[1] as Map<String, dynamic>?,
        'other_settings': results[2] as Map<String, dynamic>,
      };
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') || errorStr.contains('permission-denied')) {
        AppLogger.warning('全設定の取得が権限エラーで失敗しました',
          details: 'Firestoreセキュリティルールを確認してください。FIRESTORE_SECURITY_RULES.mdを参照してください。');
        _logAuthStatus(userId, 'getAllSettings', isError: true);
      } else {
        AppLogger.error('全設定の取得に失敗しました', error: e);
      }
      return {};
    }
  }
}

