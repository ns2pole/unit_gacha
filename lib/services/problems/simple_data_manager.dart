// lib/services/simple_data_manager.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/math_problem.dart';
import '../../models/learning_status.dart';
import '../../pages/common/problem_status.dart';
import '../../problems/unit/symbol.dart' show UnitCategory;
import '../payment/revenuecat_service.dart';
import '../auth/firebase_auth_service.dart';
import '../auth/firestore_learning_service.dart';
import '../auth/firestore_settings_service.dart';
import '../auth/firestore_attempt_event_service.dart';
import '../../managers/app_logger.dart';

class UnitGachaAttemptSyncResult {
  final int attempted; // valid events attempted to upload
  final int sent; // successfully uploaded
  final int remaining; // left in queue after sync
  final AttemptEventUpsertErrorKind? lastErrorKind;
  final String? lastErrorCode;
  final String ranAtIso;

  const UnitGachaAttemptSyncResult({
    required this.attempted,
    required this.sent,
    required this.remaining,
    this.lastErrorKind,
    this.lastErrorCode,
    required this.ranAtIso,
  });

  Map<String, dynamic> toJson() => {
    'attempted': attempted,
    'sent': sent,
    'remaining': remaining,
    'lastErrorKind': lastErrorKind?.name,
    'lastErrorCode': lastErrorCode,
    'ranAtIso': ranAtIso,
  };

  static UnitGachaAttemptSyncResult fromJson(Map<String, dynamic> json) {
    final kindStr = json['lastErrorKind'];
    AttemptEventUpsertErrorKind? kind;
    if (kindStr is String) {
      for (final k in AttemptEventUpsertErrorKind.values) {
        if (k.name == kindStr) {
          kind = k;
          break;
        }
      }
    }
    return UnitGachaAttemptSyncResult(
      attempted: (json['attempted'] as num?)?.toInt() ?? 0,
      sent: (json['sent'] as num?)?.toInt() ?? 0,
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
      lastErrorKind: kind,
      lastErrorCode: json['lastErrorCode'] as String?,
      ranAtIso:
          (json['ranAtIso'] as String?) ?? DateTime.now().toIso8601String(),
    );
  }
}

/// シンプルで拡張可能なデータ管理システム
/// 現在の必要最小限のデータ + 将来の拡張に対応
class SimpleDataManager {
  static const String _namespace = 'joymath_simple';
  static const String _version = '1.0.0';
  static const String _versionKey = '$_namespace/version';
  static const String _lastUserIdKey = '$_namespace/last_user_id';
  static const String _unitGachaAttemptQueueKey =
      '$_namespace/unit_gacha_attempt_events_queue_v1';
  static const String _unitGachaAttemptLastSyncKey =
      '$_namespace/unit_gacha_attempt_events_last_sync_v1';
  static const int _unitGachaAttemptQueueMax = 5000;

  // ============================================================================
  // Purchase recommend (category) counters
  // - We recommend purchase once per category when attempts reach a threshold.
  // ============================================================================
  static const String _purchaseRecommendAttemptCountMechanicsKey =
      '$_namespace/purchase_recommend_attempt_count_mechanics_v1';
  static const String _purchaseRecommendAttemptCountElectromagnetismKey =
      '$_namespace/purchase_recommend_attempt_count_electromagnetism_v1';
  static const String _purchaseRecommendPendingMechanicsKey =
      '$_namespace/purchase_recommend_pending_mechanics_v1';
  static const String _purchaseRecommendPendingElectromagnetismKey =
      '$_namespace/purchase_recommend_pending_electromagnetism_v1';
  static const String _purchaseRecommendShownMechanicsKey =
      '$_namespace/purchase_recommend_shown_mechanics_v1';
  static const String _purchaseRecommendShownElectromagnetismKey =
      '$_namespace/purchase_recommend_shown_electromagnetism_v1';

  static String? _attemptCountKeyFor(UnitCategory c) {
    switch (c) {
      case UnitCategory.mechanics:
        return _purchaseRecommendAttemptCountMechanicsKey;
      case UnitCategory.electromagnetism:
        return _purchaseRecommendAttemptCountElectromagnetismKey;
      case UnitCategory.thermodynamics:
      case UnitCategory.waves:
      case UnitCategory.atom:
        return null;
    }
  }

  static String? _pendingKeyFor(UnitCategory c) {
    switch (c) {
      case UnitCategory.mechanics:
        return _purchaseRecommendPendingMechanicsKey;
      case UnitCategory.electromagnetism:
        return _purchaseRecommendPendingElectromagnetismKey;
      case UnitCategory.thermodynamics:
      case UnitCategory.waves:
      case UnitCategory.atom:
        return null;
    }
  }

  static String? _shownKeyFor(UnitCategory c) {
    switch (c) {
      case UnitCategory.mechanics:
        return _purchaseRecommendShownMechanicsKey;
      case UnitCategory.electromagnetism:
        return _purchaseRecommendShownElectromagnetismKey;
      case UnitCategory.thermodynamics:
      case UnitCategory.waves:
      case UnitCategory.atom:
        return null;
    }
  }

  /// Category attempt count (unit gacha confirm presses; correct/incorrect both count).
  static Future<int> getPurchaseRecommendAttemptCount(
    UnitCategory category,
  ) async {
    final key = _attemptCountKeyFor(category);
    if (key == null) return 0;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? 0;
  }

  /// Increments and returns the updated category attempt count.
  static Future<int> incrementPurchaseRecommendAttemptCount(
    UnitCategory category,
  ) async {
    final key = _attemptCountKeyFor(category);
    if (key == null) return 0;
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, next);
    return next;
  }

  /// Whether the recommend dialog is pending to be shown (reached threshold but not shown yet).
  static Future<bool> getPurchaseRecommendPending(UnitCategory category) async {
    final key = _pendingKeyFor(category);
    if (key == null) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<void> setPurchaseRecommendPending(
    UnitCategory category,
    bool value,
  ) async {
    final key = _pendingKeyFor(category);
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// Whether the recommend dialog has already been shown (once per category).
  static Future<bool> getPurchaseRecommendShown(UnitCategory category) async {
    final key = _shownKeyFor(category);
    if (key == null) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<void> setPurchaseRecommendShown(
    UnitCategory category,
    bool value,
  ) async {
    final key = _shownKeyFor(category);
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // ============================================================================
  // Cloud sync in-flight indicator (UI can subscribe to show loading state)
  // ============================================================================
  static final ValueNotifier<int> _cloudSyncInFlight = ValueNotifier<int>(0);

  /// Cloud sync in-flight counter.
  /// - `value > 0` means some cloud sync is running.
  static ValueListenable<int> get cloudSyncInFlightListenable =>
      _cloudSyncInFlight;

  static bool get isCloudSyncing => _cloudSyncInFlight.value > 0;

  static Future<T> _withCloudSyncIndicator<T>(Future<T> Function() fn) async {
    _cloudSyncInFlight.value = _cloudSyncInFlight.value + 1;
    try {
      return await fn();
    } finally {
      final next = _cloudSyncInFlight.value - 1;
      _cloudSyncInFlight.value = next < 0 ? 0 : next;
    }
  }

  // ============================================================================
  // in-memory cache (hot paths: problem list filtering, slot rendering)
  // ============================================================================
  static final Map<String, List<Map<String, dynamic>>> _learningHistoryCache =
      {};
  static final Map<String, Map<String, dynamic>> _learningDataCache = {};
  static final Map<String, Map<String, dynamic>> _gachaSettingsCache = {};
  static Map<String, dynamic>? _userSettingsCache;
  static final Map<String, dynamic> _otherSettingsCache = {};
  static List<Map<String, dynamic>>? _unitGachaAttemptQueueCache;
  static UnitGachaAttemptSyncResult? _lastUnitGachaAttemptSyncResult;

  static UnitGachaAttemptSyncResult? get lastUnitGachaAttemptSyncResult =>
      _lastUnitGachaAttemptSyncResult;

  // ============================================================================
  // Learning data update notifier (UI can subscribe to refresh counts/filters)
  // ============================================================================
  static final ValueNotifier<int> _learningDataEpoch = ValueNotifier<int>(0);

  /// Emits when learning data changes (history updates or cloud merge updates).
  /// Pages can listen and recompute aggregates without requiring app restart.
  static ValueListenable<int> get learningDataEpochListenable =>
      _learningDataEpoch;

  static void _notifyLearningDataChanged() {
    _learningDataEpoch.value = _learningDataEpoch.value + 1;
  }

  static void _invalidateLearningCaches({bool notify = true}) {
    _learningHistoryCache.clear();
    _learningDataCache.clear();
    if (notify) _notifyLearningDataChanged();
  }

  static void _invalidateSettingsCaches({
    String? gachaType,
    String? otherSettingKey,
  }) {
    if (gachaType != null) {
      _gachaSettingsCache.remove(gachaType);
    } else {
      _gachaSettingsCache.clear();
    }
    if (otherSettingKey != null) {
      _otherSettingsCache.remove(otherSettingKey);
    } else {
      _otherSettingsCache.clear();
    }
    if (gachaType == null && otherSettingKey == null) {
      _userSettingsCache = null;
    }
  }

  static String _pendingLearningOpsKey(String problemId) =>
      '$_namespace/learning_pending_ops/$problemId';
  static String _pendingSettingsKey(String scope) =>
      '$_namespace/settings_pending/$scope';
  static String _pendingGachaSettingsScope(String gachaType) =>
      'gacha/${Uri.encodeComponent(gachaType)}';
  static const String _pendingUserSettingsScope = 'user_settings';
  static String _pendingOtherSettingScope(String key) =>
      'other/${Uri.encodeComponent(key)}';

  static String _legacyLearningKey(String problemId) =>
      '$_namespace/learning/$problemId';
  static String _legacyGachaSettingsKey(String gachaType) =>
      '$_namespace/gacha/$gachaType';
  static const String _legacyUserSettingsKey = '$_namespace/user_settings';

  static DateTime? _tryParseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _normalizeHistoryRecord(dynamic raw) {
    if (raw is! Map) return null;

    String status = 'none';
    final rawStatus = raw['status'];
    if (rawStatus is String && rawStatus.isNotEmpty) {
      status = rawStatus;
    } else if (rawStatus is ProblemStatus) {
      status = rawStatus.name;
    } else if (rawStatus is LearningStatus) {
      status = rawStatus.key;
    }

    final updatedAtDt = _tryParseDateTime(raw['updatedAt'] ?? raw['time']);
    final timeDt = _tryParseDateTime(raw['time'] ?? raw['updatedAt']);
    final normalized = <String, dynamic>{
      'status': status,
      'time': timeDt?.toIso8601String(),
      'updatedAt': updatedAtDt?.toIso8601String(),
    };
    final byCalc = raw['byCalculator'];
    if (byCalc is bool) {
      normalized['byCalculator'] = byCalc;
    }
    return normalized;
  }

  static String? _historyIdentity(Map<String, dynamic> record) {
    final updatedAt = record['updatedAt'] as String?;
    if (updatedAt != null && updatedAt.isNotEmpty) return updatedAt;
    final time = record['time'] as String?;
    if (time != null && time.isNotEmpty) return time;
    return null;
  }

  static List<Map<String, dynamic>> _normalizeHistoryList(
    dynamic historyAny, {
    int? maxEntries,
  }) {
    final byIdentity = <String, Map<String, dynamic>>{};
    if (historyAny is List) {
      for (final raw in historyAny) {
        final normalized = _normalizeHistoryRecord(raw);
        if (normalized == null) continue;
        final status = normalized['status'] as String? ?? 'none';
        final identity = _historyIdentity(normalized);
        if (identity == null || status == 'none') {
          continue;
        }

        final prev = byIdentity[identity];
        if (prev == null) {
          byIdentity[identity] = normalized;
          continue;
        }

        final prevByCalc = prev['byCalculator'] == true;
        final nextByCalc = normalized['byCalculator'] == true;
        if (!prevByCalc && nextByCalc) {
          byIdentity[identity] = normalized;
        }
      }
    }

    final out = byIdentity.values.toList()
      ..sort((a, b) {
        final timeA = _tryParseDateTime(a['updatedAt'] ?? a['time']);
        final timeB = _tryParseDateTime(b['updatedAt'] ?? b['time']);
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return -1;
        if (timeB == null) return 1;
        return timeA.compareTo(timeB);
      });

    if (maxEntries != null && out.length > maxEntries) {
      return out.sublist(out.length - maxEntries);
    }
    return out;
  }

  static String _deriveLatestStatus(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return 'none';
    return history.last['status'] as String? ?? 'none';
  }

  static String _deriveLastUpdated({
    required List<Map<String, dynamic>> history,
    String? fallbackUpdatedAt,
  }) {
    DateTime? newest;

    final historyTime = history.isNotEmpty
        ? _tryParseDateTime(history.last['updatedAt'] ?? history.last['time'])
        : null;
    if (historyTime != null) newest = historyTime;

    final fallback = _tryParseDateTime(fallbackUpdatedAt);
    if (fallback != null && (newest == null || fallback.isAfter(newest))) {
      newest = fallback;
    }

    return (newest ?? DateTime.now()).toIso8601String();
  }

  static Map<String, dynamic> _buildLearningRecordData({
    required String problemId,
    required List<Map<String, dynamic>> history,
    String? fallbackUpdatedAt,
  }) {
    final normalizedHistory = _normalizeHistoryList(
      history,
      maxEntries: learningHistoryRetentionCount,
    );
    return {
      'problemId': problemId,
      'history': normalizedHistory,
      'latestStatus': _deriveLatestStatus(normalizedHistory),
      'lastUpdated': _deriveLastUpdated(
        history: normalizedHistory,
        fallbackUpdatedAt: fallbackUpdatedAt,
      ),
    };
  }

  static Map<String, dynamic>? _normalizePendingOperation(dynamic raw) {
    if (raw is! Map) return null;
    final kind = raw['kind'] as String?;
    final updatedAt =
        _tryParseDateTime(raw['updatedAt'])?.toIso8601String() ??
        DateTime.now().toIso8601String();
    switch (kind) {
      case 'append':
        final log = _normalizeHistoryRecord(raw['log']);
        if (log == null) return null;
        return {'kind': 'append', 'updatedAt': updatedAt, 'log': log};
      case 'replace':
        return {
          'kind': 'replace',
          'updatedAt': updatedAt,
          'history': _normalizeHistoryList(
            raw['history'],
            maxEntries: learningHistoryRetentionCount,
          ),
        };
      case 'clear':
        return {'kind': 'clear', 'updatedAt': updatedAt};
      default:
        return null;
    }
  }

  static Future<List<Map<String, dynamic>>> _loadPendingLearningOperations(
    SharedPreferences prefs,
    String problemId,
  ) async {
    final raw = prefs.getString(_pendingLearningOpsKey(problemId));
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        if (decoded is List) {
          return decoded
              .map(_normalizePendingOperation)
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      } catch (_) {}
    }

    final legacyRaw = prefs.getString(_legacyLearningKey(problemId));
    if (legacyRaw != null && legacyRaw.isNotEmpty) {
      try {
        final decoded = json.decode(legacyRaw);
        final history = decoded is Map<String, dynamic>
            ? _normalizeHistoryList(
                decoded['history'],
                maxEntries: learningHistoryRetentionCount,
              )
            : _normalizeHistoryList(
                decoded,
                maxEntries: learningHistoryRetentionCount,
              );
        if (history.isNotEmpty) {
          final migrated = [
            {
              'kind': 'replace',
              'updatedAt':
                  (decoded is Map<String, dynamic>
                      ? decoded['lastUpdated'] as String?
                      : null) ??
                  _deriveLastUpdated(history: history),
              'history': history,
            },
          ];
          await prefs.setString(
            _pendingLearningOpsKey(problemId),
            json.encode(migrated),
          );
          await prefs.remove(_legacyLearningKey(problemId));
          return migrated;
        }
        await prefs.remove(_legacyLearningKey(problemId));
      } catch (_) {}
    }
    return const [];
  }

  static Future<void> _savePendingLearningOperations(
    SharedPreferences prefs,
    String problemId,
    List<Map<String, dynamic>> operations, {
    bool notify = true,
  }) async {
    final normalized = operations
        .map(_normalizePendingOperation)
        .whereType<Map<String, dynamic>>()
        .toList();
    if (normalized.isEmpty) {
      await prefs.remove(_pendingLearningOpsKey(problemId));
    } else {
      await prefs.setString(
        _pendingLearningOpsKey(problemId),
        json.encode(normalized),
      );
    }
    await prefs.remove(_legacyLearningKey(problemId));
    _learningHistoryCache.remove(problemId);
    _learningDataCache.remove(problemId);
    if (notify) _notifyLearningDataChanged();
  }

  static List<Map<String, dynamic>> _applyPendingLearningOperations(
    List<Map<String, dynamic>> baseHistory,
    List<Map<String, dynamic>> operations,
  ) {
    var history = _normalizeHistoryList(
      baseHistory,
      maxEntries: learningHistoryRetentionCount,
    );
    for (final operation in operations) {
      switch (operation['kind']) {
        case 'append':
          history = _normalizeHistoryList([
            ...history,
            operation['log'],
          ], maxEntries: learningHistoryRetentionCount);
          break;
        case 'replace':
          history = _normalizeHistoryList(
            operation['history'],
            maxEntries: learningHistoryRetentionCount,
          );
          break;
        case 'clear':
          history = const [];
          break;
      }
    }
    return history;
  }

  static Future<Map<String, dynamic>?> _fetchCloudLearningRecord(
    String userId,
    String problemId,
  ) async {
    final remote = await FirestoreLearningService.getLearningRecord(
      userId: userId,
      problemId: problemId,
    );
    if (remote == null) return null;
    return _buildLearningRecordData(
      problemId: problemId,
      history: _normalizeHistoryList(
        remote['history'],
        maxEntries: learningHistoryRetentionCount,
      ),
      fallbackUpdatedAt: remote['lastUpdated'] as String?,
    );
  }

  static Future<Map<String, dynamic>> _resolveDisplayLearningData(
    String problemId,
  ) async {
    final canUseCache = !FirebaseAuthService.isAuthenticated;
    final cached = _learningDataCache[problemId];
    if (canUseCache && cached != null) return Map<String, dynamic>.from(cached);

    final prefs = await SharedPreferences.getInstance();
    final pendingOperations = await _loadPendingLearningOperations(
      prefs,
      problemId,
    );

    Map<String, dynamic>? cloudData;
    final userId = FirebaseAuthService.userId;
    if (FirebaseAuthService.isAuthenticated && userId != null) {
      try {
        cloudData = await _fetchCloudLearningRecord(userId, problemId);
      } catch (_) {
        cloudData = null;
      }
    }

    final resolvedHistory = _applyPendingLearningOperations(
      cloudData?['history'] as List<Map<String, dynamic>>? ?? const [],
      pendingOperations,
    );
    final resolved = _buildLearningRecordData(
      problemId: problemId,
      history: resolvedHistory,
      fallbackUpdatedAt: cloudData?['lastUpdated'] as String?,
    );
    if (canUseCache) {
      _learningDataCache[problemId] = Map<String, dynamic>.from(resolved);
      _learningHistoryCache[problemId] = List<Map<String, dynamic>>.from(
        resolvedHistory,
      );
    }
    return Map<String, dynamic>.from(resolved);
  }

  static Future<void> _enqueuePendingLearningOperation(
    String problemId,
    Map<String, dynamic> operation,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await _loadPendingLearningOperations(prefs, problemId);
    existing.add(operation);
    await _savePendingLearningOperations(prefs, problemId, existing);
  }

  static Future<bool> _syncPendingLearningRecord(
    SharedPreferences prefs,
    String userId,
    String problemId,
  ) async {
    final pendingOperations = await _loadPendingLearningOperations(
      prefs,
      problemId,
    );
    if (pendingOperations.isEmpty) return false;

    final cloudData = await _fetchCloudLearningRecord(userId, problemId);
    final mergedHistory = _applyPendingLearningOperations(
      cloudData?['history'] as List<Map<String, dynamic>>? ?? const [],
      pendingOperations,
    );
    final mergedRecord = _buildLearningRecordData(
      problemId: problemId,
      history: mergedHistory,
      fallbackUpdatedAt: cloudData?['lastUpdated'] as String?,
    );
    final success = await FirestoreLearningService.saveLearningRecord(
      userId: userId,
      problemId: problemId,
      data: mergedRecord,
    );
    if (!success) return false;

    await _savePendingLearningOperations(
      prefs,
      problemId,
      const [],
      notify: false,
    );
    _learningDataCache[problemId] = Map<String, dynamic>.from(mergedRecord);
    _learningHistoryCache[problemId] = List<Map<String, dynamic>>.from(
      mergedHistory,
    );
    _notifyLearningDataChanged();
    return true;
  }

  static dynamic _cloneJsonValue(dynamic value) {
    if (value == null) return null;
    try {
      return json.decode(json.encode(value));
    } catch (_) {
      return null;
    }
  }

  static List<String> _normalizeStringList(
    dynamic raw, {
    int? maxLength,
  }) {
    List<String> out = const [];
    if (raw is List) {
      out = raw.whereType<String>().toList();
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        if (decoded is List) {
          out = decoded.whereType<String>().toList();
        }
      } catch (_) {}
    }
    if (maxLength != null && out.length > maxLength) {
      return out.take(maxLength).toList();
    }
    return out;
  }

  static Map<String, dynamic>? _buildPendingSettingReplaceOperation(
    dynamic value, {
    String? updatedAt,
  }) {
    final normalizedValue = _cloneJsonValue(value);
    if (normalizedValue == null) return null;
    return {
      'kind': 'replace',
      'updatedAt':
          _tryParseDateTime(updatedAt)?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'value': normalizedValue,
    };
  }

  static Map<String, dynamic>? _normalizePendingSettingOperation(dynamic raw) {
    if (raw is! Map) return null;
    final kind = raw['kind'] as String?;
    final updatedAt =
        _tryParseDateTime(raw['updatedAt'])?.toIso8601String() ??
        DateTime.now().toIso8601String();
    switch (kind) {
      case 'replace':
        final value = _cloneJsonValue(raw['value']);
        if (value == null) return null;
        return {'kind': 'replace', 'updatedAt': updatedAt, 'value': value};
      case 'clear':
        return {'kind': 'clear', 'updatedAt': updatedAt};
      default:
        return null;
    }
  }

  static Future<Map<String, dynamic>?> _loadPendingSettingOperation(
    SharedPreferences prefs,
    String scope, {
    required Future<Map<String, dynamic>?> Function() loadLegacy,
  }) async {
    final raw = prefs.getString(_pendingSettingsKey(scope));
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        final normalized = _normalizePendingSettingOperation(decoded);
        if (normalized != null) return normalized;
      } catch (_) {}
    }

    final migrated = await loadLegacy();
    if (migrated != null) {
      final normalized = _normalizePendingSettingOperation(migrated);
      if (normalized != null) {
        await prefs.setString(
          _pendingSettingsKey(scope),
          json.encode(normalized),
        );
        return normalized;
      }
    }
    return null;
  }

  static Future<void> _savePendingSettingOperation(
    SharedPreferences prefs,
    String scope,
    Map<String, dynamic>? operation, {
    required void Function() invalidateCache,
  }) async {
    final normalized = operation == null
        ? null
        : _normalizePendingSettingOperation(operation);
    if (normalized == null) {
      await prefs.remove(_pendingSettingsKey(scope));
    } else {
      await prefs.setString(_pendingSettingsKey(scope), json.encode(normalized));
    }
    invalidateCache();
  }

  static dynamic _applyPendingSettingOperation(
    dynamic baseValue,
    Map<String, dynamic>? operation,
  ) {
    final clonedBase = _cloneJsonValue(baseValue);
    if (operation == null) return clonedBase;
    switch (operation['kind']) {
      case 'replace':
        return _cloneJsonValue(operation['value']);
      case 'clear':
        return null;
      default:
        return clonedBase;
    }
  }

  static Future<Map<String, dynamic>?> _loadLegacyGachaSettingsOperation(
    SharedPreferences prefs,
    String gachaType,
  ) async {
    final raw = prefs.getString(_legacyGachaSettingsKey(gachaType));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is Map) {
        final settings = _getDefaultGachaSettings()
          ..addAll(Map<String, dynamic>.from(decoded));
        final op = _buildPendingSettingReplaceOperation(
          settings,
          updatedAt: settings['lastUpdated'] as String?,
        );
        await prefs.remove(_legacyGachaSettingsKey(gachaType));
        return op;
      }
    } catch (_) {}
    await prefs.remove(_legacyGachaSettingsKey(gachaType));
    return null;
  }

  static Future<Map<String, dynamic>?> _loadLegacyUserSettingsOperation(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_legacyUserSettingsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is Map) {
        final settings = Map<String, dynamic>.from(decoded);
        final op = _buildPendingSettingReplaceOperation(
          settings,
          updatedAt: settings['lastUpdated'] as String?,
        );
        await prefs.remove(_legacyUserSettingsKey);
        return op;
      }
    } catch (_) {}
    await prefs.remove(_legacyUserSettingsKey);
    return null;
  }

  static Future<Map<String, dynamic>?> _loadLegacyOtherSettingOperation(
    SharedPreferences prefs,
    String key, {
    dynamic Function(dynamic raw)? legacyDecoder,
  }) async {
    if (!prefs.containsKey(key)) return null;
    final raw = prefs.get(key);
    final value = legacyDecoder != null ? legacyDecoder(raw) : raw;
    await prefs.remove(key);
    return _buildPendingSettingReplaceOperation(value);
  }

  static Future<Map<String, dynamic>?> _fetchCloudGachaSettings(
    String userId,
    String gachaType,
  ) async {
    final remote = await FirestoreSettingsService.getGachaSettings(
      userId: userId,
      gachaType: gachaType,
    );
    if (remote == null) return null;
    final merged = _getDefaultGachaSettings()..addAll(remote);
    return merged;
  }

  static Future<Map<String, dynamic>> _resolveDisplayGachaSettings(
    String gachaType,
  ) async {
    final canUseCache = !FirebaseAuthService.isAuthenticated;
    final cached = _gachaSettingsCache[gachaType];
    if (canUseCache && cached != null) {
      return Map<String, dynamic>.from(cached);
    }

    final prefs = await SharedPreferences.getInstance();
    final pending = await _loadPendingSettingOperation(
      prefs,
      _pendingGachaSettingsScope(gachaType),
      loadLegacy: () => _loadLegacyGachaSettingsOperation(prefs, gachaType),
    );

    Map<String, dynamic>? cloudData;
    final userId = FirebaseAuthService.userId;
    if (FirebaseAuthService.isAuthenticated && userId != null) {
      try {
        cloudData = await _fetchCloudGachaSettings(userId, gachaType);
      } catch (_) {
        cloudData = null;
      }
    }

    final resolvedRaw = _applyPendingSettingOperation(
      cloudData ?? _getDefaultGachaSettings(),
      pending,
    );
    final resolved = _getDefaultGachaSettings();
    if (resolvedRaw is Map) {
      resolved.addAll(Map<String, dynamic>.from(resolvedRaw));
    }
    if (canUseCache) {
      _gachaSettingsCache[gachaType] = Map<String, dynamic>.from(resolved);
    }
    return Map<String, dynamic>.from(resolved);
  }

  static Future<Map<String, dynamic>> _resolveDisplayUserSettings() async {
    final canUseCache = !FirebaseAuthService.isAuthenticated;
    if (canUseCache && _userSettingsCache != null) {
      return Map<String, dynamic>.from(_userSettingsCache!);
    }

    final prefs = await SharedPreferences.getInstance();
    final pending = await _loadPendingSettingOperation(
      prefs,
      _pendingUserSettingsScope,
      loadLegacy: () => _loadLegacyUserSettingsOperation(prefs),
    );

    Map<String, dynamic>? cloudData;
    final userId = FirebaseAuthService.userId;
    if (FirebaseAuthService.isAuthenticated && userId != null) {
      try {
        cloudData = await FirestoreSettingsService.getUserSettings(userId: userId);
      } catch (_) {
        cloudData = null;
      }
    }

    final resolvedRaw = _applyPendingSettingOperation(cloudData ?? const {}, pending);
    final resolved = resolvedRaw is Map
        ? Map<String, dynamic>.from(resolvedRaw)
        : <String, dynamic>{};
    if (canUseCache) {
      _userSettingsCache = Map<String, dynamic>.from(resolved);
    }
    return Map<String, dynamic>.from(resolved);
  }

  static Future<dynamic> getOtherSettingValue(
    String key, {
    dynamic Function(dynamic raw)? legacyDecoder,
  }) async {
    final canUseCache = !FirebaseAuthService.isAuthenticated;
    if (canUseCache && _otherSettingsCache.containsKey(key)) {
      return _cloneJsonValue(_otherSettingsCache[key]);
    }

    final prefs = await SharedPreferences.getInstance();
    final pending = await _loadPendingSettingOperation(
      prefs,
      _pendingOtherSettingScope(key),
      loadLegacy: () => _loadLegacyOtherSettingOperation(
        prefs,
        key,
        legacyDecoder: legacyDecoder,
      ),
    );

    dynamic cloudValue;
    final userId = FirebaseAuthService.userId;
    if (FirebaseAuthService.isAuthenticated && userId != null) {
      try {
        cloudValue = await FirestoreSettingsService.getOtherSetting(
          userId: userId,
          key: key,
        );
      } catch (_) {
        cloudValue = null;
      }
    }

    final resolved = _applyPendingSettingOperation(cloudValue, pending);
    if (canUseCache) {
      _otherSettingsCache[key] = _cloneJsonValue(resolved);
    }
    return _cloneJsonValue(resolved);
  }

  static Future<bool> _syncPendingGachaSettings(
    SharedPreferences prefs,
    String userId,
    String gachaType,
  ) async {
    final pending = await _loadPendingSettingOperation(
      prefs,
      _pendingGachaSettingsScope(gachaType),
      loadLegacy: () => _loadLegacyGachaSettingsOperation(prefs, gachaType),
    );
    if (pending == null) return false;

    final resolvedRaw = _applyPendingSettingOperation(
      _getDefaultGachaSettings(),
      pending,
    );
    final settings = _getDefaultGachaSettings();
    if (resolvedRaw is Map) {
      settings.addAll(Map<String, dynamic>.from(resolvedRaw));
    }
    final success = await FirestoreSettingsService.saveGachaSettings(
      userId: userId,
      gachaType: gachaType,
      settings: settings,
    );
    if (!success) return false;

    await _savePendingSettingOperation(
      prefs,
      _pendingGachaSettingsScope(gachaType),
      null,
      invalidateCache: () => _invalidateSettingsCaches(gachaType: gachaType),
    );
    _gachaSettingsCache[gachaType] = Map<String, dynamic>.from(settings);
    return true;
  }

  static Future<bool> _syncPendingUserSettings(
    SharedPreferences prefs,
    String userId,
  ) async {
    final pending = await _loadPendingSettingOperation(
      prefs,
      _pendingUserSettingsScope,
      loadLegacy: () => _loadLegacyUserSettingsOperation(prefs),
    );
    if (pending == null) return false;

    final resolvedRaw = _applyPendingSettingOperation(const {}, pending);
    final settings = resolvedRaw is Map
        ? Map<String, dynamic>.from(resolvedRaw)
        : <String, dynamic>{};
    final success = await FirestoreSettingsService.saveUserSettings(
      userId: userId,
      settings: settings,
    );
    if (!success) return false;

    await _savePendingSettingOperation(
      prefs,
      _pendingUserSettingsScope,
      null,
      invalidateCache: _invalidateSettingsCaches,
    );
    _userSettingsCache = Map<String, dynamic>.from(settings);
    return true;
  }

  static Future<bool> _syncPendingOtherSetting(
    SharedPreferences prefs,
    String userId,
    String key, {
    dynamic Function(dynamic raw)? legacyDecoder,
  }) async {
    final pending = await _loadPendingSettingOperation(
      prefs,
      _pendingOtherSettingScope(key),
      loadLegacy: () => _loadLegacyOtherSettingOperation(
        prefs,
        key,
        legacyDecoder: legacyDecoder,
      ),
    );
    if (pending == null) return false;

    final value = _applyPendingSettingOperation(null, pending);
    final success = await FirestoreSettingsService.saveOtherSetting(
      userId: userId,
      key: key,
      value: value,
    );
    if (!success) return false;

    await _savePendingSettingOperation(
      prefs,
      _pendingOtherSettingScope(key),
      null,
      invalidateCache: () => _invalidateSettingsCaches(otherSettingKey: key),
    );
    _otherSettingsCache[key] = _cloneJsonValue(value);
    return true;
  }

  static List<String>? _decodeSelectedFreeGachasLegacyValue(dynamic raw) {
    final out = _normalizeStringList(raw, maxLength: 2);
    return out.isEmpty ? null : out;
  }

  static Future<void> _migrateLegacySettingsToPending(
    SharedPreferences prefs,
  ) async {
    final allKeys = prefs.getKeys();

    final gachaTypes = allKeys
        .where(
          (key) =>
              key.startsWith('$_namespace/gacha/') &&
              key != '$_namespace/gacha',
        )
        .map((key) => key.replaceFirst('$_namespace/gacha/', ''))
        .toList();
    for (final gachaType in gachaTypes) {
      await _loadPendingSettingOperation(
        prefs,
        _pendingGachaSettingsScope(gachaType),
        loadLegacy: () => _loadLegacyGachaSettingsOperation(prefs, gachaType),
      );
    }

    await _loadPendingSettingOperation(
      prefs,
      _pendingUserSettingsScope,
      loadLegacy: () => _loadLegacyUserSettingsOperation(prefs),
    );

    final otherKeys = <String>{
      'integral_gacha_exclusion_mode',
      'limit_gacha_exclusion_mode',
      'sequence_gacha_exclusion_mode',
      'unit_gacha_exclusion_mode',
      'integral_gacha_max_selections',
      'limit_gacha_max_selections',
      'sequence_gacha_max_selections',
      'unit_gacha_max_selections',
      'unit_gacha_selected_categories',
      'unit_reference_table_selected_category',
      _selectedFreeGachasKey,
      ...allKeys.where(
        (key) =>
            key.endsWith('_aggregation_mode_v1') &&
            ![
              'unit',
              'integral',
              'limit',
              'sequence',
              'congruence',
            ].any((type) => key.startsWith('${type}_aggregation_mode_v1')),
      ),
    };

    for (final key in otherKeys) {
      final legacyDecoder = key == _selectedFreeGachasKey
          ? _decodeSelectedFreeGachasLegacyValue
          : null;
      await _loadPendingSettingOperation(
        prefs,
        _pendingOtherSettingScope(key),
        loadLegacy: () => _loadLegacyOtherSettingOperation(
          prefs,
          key,
          legacyDecoder: legacyDecoder,
        ),
      );
    }
  }

  // ============================================================================
  // 初期化とバージョン管理
  // ============================================================================

  /// システムの初期化
  static Future<bool> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getString(_versionKey);

      if (currentVersion != _version) {
        AppLogger.info('SimpleDataManagerを初期化中', details: 'バージョン: $_version');

        // バージョンを更新
        await prefs.setString(_versionKey, _version);

        AppLogger.success('SimpleDataManagerの初期化が完了しました');
      }

      // 認証済みユーザーの場合、未同期データがあればクラウドへ反映する
      if (FirebaseAuthService.isAuthenticated) {
        await Future.wait([
          syncLocalDataToFirestore(),
          syncLocalSettingsToFirestore(),
        ]);
      }

      return true;
    } catch (e) {
      AppLogger.error('SimpleDataManagerの初期化に失敗しました', error: e);
      return false;
    }
  }

  // ============================================================================
  // unit_gacha attempt events (ranking source of truth)
  // ============================================================================

  static Future<int> getUnitGachaAttemptQueueLength() async {
    final prefs = await SharedPreferences.getInstance();
    final q = await _loadUnitGachaAttemptQueue(prefs);
    return q.length;
  }

  static Future<UnitGachaAttemptSyncResult?>
  loadLastUnitGachaAttemptSyncResult() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_unitGachaAttemptLastSyncKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is Map) {
        final r = UnitGachaAttemptSyncResult.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        _lastUnitGachaAttemptSyncResult = r;
        return r;
      }
    } catch (_) {}
    return null;
  }

  static UnitGachaAttemptSyncResult? _decodeLastUnitGachaAttemptSyncResult(
    String? raw,
  ) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is Map) {
        return UnitGachaAttemptSyncResult.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {}
    return null;
  }

  /// 電卓Enter由来の解答イベントをローカルキューに追加する。
  /// - オフライン/未ログイン時でも溜められる
  /// - ログイン後に syncUnitGachaAttemptEventsToFirestore() でまとめてアップロード
  static Future<void> enqueueUnitGachaAttemptEvent({
    required String problemId,
    required bool isCorrect,
  }) async {
    final status = isCorrect ? 'solved' : 'failed';
    final clientTime = DateTime.now().toIso8601String();
    final eventId = _buildStableAttemptEventId(
      problemId: problemId,
      clientTimeIso: clientTime,
    );

    final prefs = await SharedPreferences.getInstance();
    final q = await _loadUnitGachaAttemptQueue(prefs);

    // 重複防止（同じeventIdが既にあれば追加しない）
    final exists = q.any((e) => e['eventId'] == eventId);
    if (!exists) {
      q.add({
        'eventId': eventId,
        'problemId': problemId,
        'status': status,
        'clientTime': clientTime,
      });
    }

    // キュー肥大化の防止（古いものから捨てる）
    if (q.length > _unitGachaAttemptQueueMax) {
      q.removeRange(0, q.length - _unitGachaAttemptQueueMax);
    }

    await _saveUnitGachaAttemptQueue(prefs, q);

    // ログイン済みなら、その場で送信も試す（失敗してもキューに残る）
    if (FirebaseAuthService.isAuthenticated) {
      unawaited(syncUnitGachaAttemptEventsToFirestore().then((_) {}));
    }
  }

  static String _buildStableAttemptEventId({
    required String problemId,
    required String clientTimeIso,
  }) {
    // Firestore docIdとして安全な形に寄せる（スラッシュ等を潰す）
    final safeProblemId = problemId.replaceAll('/', '_');
    final safeTime = clientTimeIso.replaceAll(':', '').replaceAll('.', '');
    return 'u_${safeProblemId}_$safeTime';
  }

  static Future<List<Map<String, dynamic>>> _loadUnitGachaAttemptQueue(
    SharedPreferences prefs,
  ) async {
    final cached = _unitGachaAttemptQueueCache;
    if (cached != null) return List<Map<String, dynamic>>.from(cached);

    final raw = prefs.getString(_unitGachaAttemptQueueKey);
    if (raw == null || raw.isEmpty) {
      _unitGachaAttemptQueueCache = <Map<String, dynamic>>[];
      return <Map<String, dynamic>>[];
    }
    try {
      final decoded = json.decode(raw);
      if (decoded is List) {
        final q = decoded
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        _unitGachaAttemptQueueCache = q;
        return List<Map<String, dynamic>>.from(q);
      }
    } catch (_) {}
    _unitGachaAttemptQueueCache = <Map<String, dynamic>>[];
    return <Map<String, dynamic>>[];
  }

  static Future<void> _saveUnitGachaAttemptQueue(
    SharedPreferences prefs,
    List<Map<String, dynamic>> queue,
  ) async {
    _unitGachaAttemptQueueCache = List<Map<String, dynamic>>.from(queue);
    await prefs.setString(_unitGachaAttemptQueueKey, json.encode(queue));
  }

  /// ローカルに溜まった unit_gacha の解答イベントをFirestoreへ送る。
  /// - 送信成功したものだけキューから削除
  /// - permission系エラーが出る場合は早期終了（再試行しても無駄なので）
  static Future<UnitGachaAttemptSyncResult>
  syncUnitGachaAttemptEventsToFirestore() async {
    if (!FirebaseAuthService.isAuthenticated) {
      final r = UnitGachaAttemptSyncResult(
        attempted: 0,
        sent: 0,
        remaining: 0,
        lastErrorKind: AttemptEventUpsertErrorKind.unauthenticated,
        lastErrorCode: 'unauthenticated',
        ranAtIso: DateTime.now().toIso8601String(),
      );
      _lastUnitGachaAttemptSyncResult = r;
      return r;
    }
    final userId = FirebaseAuthService.userId;
    if (userId == null) {
      final r = UnitGachaAttemptSyncResult(
        attempted: 0,
        sent: 0,
        remaining: 0,
        lastErrorKind: AttemptEventUpsertErrorKind.unauthenticated,
        lastErrorCode: 'userId_null',
        ranAtIso: DateTime.now().toIso8601String(),
      );
      _lastUnitGachaAttemptSyncResult = r;
      return r;
    }

    final prefs = await SharedPreferences.getInstance();
    final queue = await _loadUnitGachaAttemptQueue(prefs);
    if (queue.isEmpty) {
      // IMPORTANT: Do not overwrite the last successful/failed sync result with zeros.
      // Queue can be empty simply because events were already uploaded (or never enqueued).
      final prev = _decodeLastUnitGachaAttemptSyncResult(
        prefs.getString(_unitGachaAttemptLastSyncKey),
      );
      if (prev != null) {
        _lastUnitGachaAttemptSyncResult = prev;
        return prev;
      }
      final r = UnitGachaAttemptSyncResult(
        attempted: 0,
        sent: 0,
        remaining: 0,
        ranAtIso: DateTime.now().toIso8601String(),
      );
      _lastUnitGachaAttemptSyncResult = r;
      // First-time only: persist so UI has something to show next boot.
      await _saveLastUnitGachaAttemptSyncResult(prefs, r);
      return r;
    }

    return await _withCloudSyncIndicator(() async {
      final remaining = <Map<String, dynamic>>[];
      bool hasPermissionError = false;
      int attempted = 0;
      int sent = 0;
      AttemptEventUpsertErrorKind? lastErrorKind;
      String? lastErrorCode;

      for (final e in queue) {
        if (hasPermissionError) {
          remaining.add(e);
          continue;
        }
        final eventId = e['eventId'] as String?;
        final problemId = e['problemId'] as String?;
        final status = e['status'] as String?;
        final clientTime = e['clientTime'] as String?;

        if (eventId == null ||
            problemId == null ||
            status == null ||
            clientTime == null) {
          continue; // 壊れたレコードは捨てる
        }
        if (status != 'solved' && status != 'failed') {
          continue;
        }

        try {
          attempted += 1;
          final res = await FirestoreAttemptEventService.upsertAttemptEvent(
            userId: userId,
            eventId: eventId,
            problemId: problemId,
            status: status,
            clientTimeIso: clientTime,
          );
          if (res.ok) {
            sent += 1;
          } else {
            lastErrorKind = res.errorKind;
            lastErrorCode = res.errorCode;
            if (res.errorKind == AttemptEventUpsertErrorKind.permissionDenied) {
              hasPermissionError = true;
            }
            remaining.add(e);
          }
        } catch (err) {
          // Should be rare; upsertAttemptEvent already classifies errors.
          lastErrorKind = AttemptEventUpsertErrorKind.unknown;
          lastErrorCode = 'thrown';
          remaining.add(e);
        }
      }

      await _saveUnitGachaAttemptQueue(prefs, remaining);
      final r = UnitGachaAttemptSyncResult(
        attempted: attempted,
        sent: sent,
        remaining: remaining.length,
        lastErrorKind: lastErrorKind,
        lastErrorCode: lastErrorCode,
        ranAtIso: DateTime.now().toIso8601String(),
      );
      _lastUnitGachaAttemptSyncResult = r;
      await _saveLastUnitGachaAttemptSyncResult(prefs, r);
      return r;
    });
  }

  static Future<void> _saveLastUnitGachaAttemptSyncResult(
    SharedPreferences prefs,
    UnitGachaAttemptSyncResult r,
  ) async {
    try {
      await prefs.setString(
        _unitGachaAttemptLastSyncKey,
        json.encode(r.toJson()),
      );
    } catch (_) {}
  }

  /// ローカル設定をFirestoreに同期（認証時に呼び出す）
  static Future<void> syncLocalSettingsToFirestore() async {
    try {
      if (!FirebaseAuthService.isAuthenticated) {
        print('User not authenticated, skipping Firestore settings sync');
        return;
      }

      final userId = FirebaseAuthService.userId;
      if (userId == null) {
        print('User ID is null, skipping Firestore settings sync');
        return;
      }
      await _withCloudSyncIndicator(() async {
        print('Starting pending settings sync to Firestore for user: $userId');

        final prefs = await SharedPreferences.getInstance();
        await _migrateLegacySettingsToPending(prefs);

        final pendingScopes = prefs
            .getKeys()
            .where((key) => key.startsWith('$_namespace/settings_pending/'))
            .map(
              (key) => key.replaceFirst('$_namespace/settings_pending/', ''),
            )
            .toList()
          ..sort();

        for (final scope in pendingScopes) {
          try {
            if (scope.startsWith('gacha/')) {
              final gachaType = Uri.decodeComponent(
                scope.replaceFirst('gacha/', ''),
              );
              await _syncPendingGachaSettings(prefs, userId, gachaType);
              continue;
            }
            if (scope == _pendingUserSettingsScope) {
              await _syncPendingUserSettings(prefs, userId);
              continue;
            }
            if (scope.startsWith('other/')) {
              final key = Uri.decodeComponent(
                scope.replaceFirst('other/', ''),
              );
              final legacyDecoder = key == _selectedFreeGachasKey
                  ? _decodeSelectedFreeGachasLegacyValue
                  : null;
              await _syncPendingOtherSetting(
                prefs,
                userId,
                key,
                legacyDecoder: legacyDecoder,
              );
            }
          } catch (e) {
            print('Error syncing pending setting scope $scope: $e');
          }
        }

        print('Pending settings sync to Firestore completed');
      });
    } catch (e) {
      print('Error syncing local settings to Firestore: $e');
    }
  }

  /// ローカルデータをFirestoreに同期（認証時に呼び出す）
  static Future<void> syncLocalDataToFirestore() async {
    try {
      if (!FirebaseAuthService.isAuthenticated) {
        print('User not authenticated, skipping Firestore sync');
        return;
      }

      final userId = FirebaseAuthService.userId;
      if (userId == null) {
        print('User ID is null, skipping Firestore sync');
        return;
      }

      await _withCloudSyncIndicator(() async {
        print('Starting pending learning log sync for user: $userId');
        final prefs = await SharedPreferences.getInstance();
        final pendingProblemIds =
            prefs
                .getKeys()
                .where(
                  (key) => key.startsWith('$_namespace/learning_pending_ops/'),
                )
                .map(
                  (key) =>
                      key.replaceFirst('$_namespace/learning_pending_ops/', ''),
                )
                .toList()
              ..sort();
        for (final problemId in pendingProblemIds) {
          try {
            await _syncPendingLearningRecord(prefs, userId, problemId);
          } catch (e) {
            print('Error syncing pending learning record $problemId: $e');
          }
        }
        // 解答イベント（ランキング用）も同期
        await syncUnitGachaAttemptEventsToFirestore();
      });
    } catch (e) {
      print('Error syncing local data to Firestore: $e');
    }
  }

  // ============================================================================
  // 学習記録管理（シンプル版）
  // ============================================================================

  /// 学習記録を保存
  static Future<bool> saveLearningRecord(
    dynamic problem,
    dynamic status, {
    bool byCalculator = false,
  }) async {
    try {
      final statusKey = status is LearningStatus
          ? status.key
          : status is ProblemStatus
          ? status.name
          : 'none';
      if (statusKey == 'none') return true;

      final nowIso = DateTime.now().toIso8601String();
      await _enqueuePendingLearningOperation(problem.id, {
        'kind': 'append',
        'updatedAt': nowIso,
        'log': {
          'status': statusKey,
          'time': nowIso,
          'updatedAt': nowIso,
          if (byCalculator) 'byCalculator': true,
        },
      });

      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.userId;
        if (userId != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await _syncPendingLearningRecord(prefs, userId, problem.id);
            print(
              'Successfully synced learning record for problem ${problem.id}',
            );
          } catch (e, stackTrace) {
            print('Error saving to Firestore (continuing with local save): $e');
            print('Stack trace: $stackTrace');
          }
        }
      }

      return true;
    } catch (e) {
      print('Error saving learning record: $e');
      return false;
    }
  }

  /// 学習記録を取得
  /// ローカルデータを優先して即座に返し、バックグラウンドでFirestoreと同期
  static Future<LearningStatus> getLearningRecord(MathProblem problem) async {
    try {
      final data = await _resolveDisplayLearningData(problem.id);
      final statusKey = data['latestStatus'] as String?;
      if (statusKey != null) {
        return LearningStatusExtension.fromKey(statusKey);
      }
      return LearningStatus.none;
    } catch (e) {
      print('Error getting learning record: $e');
      // エラー時はnoneを返す（問題は除外されない）
      return LearningStatus.none;
    }
  }

  /// 学習記録の履歴を取得
  /// ローカルデータを優先して即座に返し、バックグラウンドでFirestoreと同期
  static Future<List<Map<String, dynamic>>> getLearningHistory(
    dynamic problem,
  ) async {
    try {
      return _getLearningHistoryForProblemId(problem.id);
    } catch (e) {
      print('Error getting learning history: $e');
      // エラー時は空のリストを返す（問題は除外されない）
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _getLearningHistoryForProblemId(
    String problemId,
  ) async {
    final canUseCache = !FirebaseAuthService.isAuthenticated;
    final cached = _learningHistoryCache[problemId];
    if (canUseCache && cached != null) return cached;

    final data = await _resolveDisplayLearningData(problemId);
    final history = _normalizeHistoryList(
      data['history'],
      maxEntries: learningHistoryRetentionCount,
    );

    final migratedHistory = history.map((h) {
      final status = h['status'] as String?;
      final time = h['time'] as String?;
      final byCalc = h['byCalculator'];

      String newStatus;
      switch (status) {
        case 'solved':
          newStatus = 'solved';
          break;
        case 'understood':
          newStatus = 'understood';
          break;
        case 'failed':
          newStatus = 'failed';
          break;
        default:
          newStatus = 'none';
      }

      final out = <String, dynamic>{'status': newStatus, 'time': time};
      if (byCalc is bool) {
        out['byCalculator'] = byCalc;
      }
      final updatedAt = h['updatedAt'] as String?;
      if (updatedAt != null) {
        out['updatedAt'] = updatedAt;
      }
      return out;
    }).toList();

    if (canUseCache) {
      _learningHistoryCache[problemId] = migratedHistory;
    }
    return migratedHistory;
  }

  /// 複数問題の履歴を一括取得（SharedPreferencesアクセス回数を最小化）
  ///
  /// - 問題一覧で大量にgetLearningHistoryを呼ぶと重くなるため、先にまとめて読み込む。
  /// - Firestore同期は行わない（UIをブロックしないため）。
  static Future<Map<String, List<Map<String, dynamic>>>> getLearningHistoryMap(
    Iterable<String> problemIds,
  ) async {
    final ids = problemIds.toSet();
    if (ids.isEmpty) return {};
    final out = <String, List<Map<String, dynamic>>>{};

    for (final id in ids) {
      final cached = _learningHistoryCache[id];
      if (cached != null) {
        out[id] = cached;
        continue;
      }

      final history = await _getLearningHistoryForProblemId(id);
      out[id] = history;
    }

    return out;
  }

  /// 学習記録の履歴を保存
  static Future<bool> saveLearningHistory(
    dynamic problem,
    List<Map<String, dynamic>> history,
  ) async {
    try {
      final normalizedHistory = _normalizeHistoryList(
        history,
        maxEntries: learningHistoryRetentionCount,
      );
      final nowIso = DateTime.now().toIso8601String();
      await _enqueuePendingLearningOperation(problem.id, {
        'kind': 'replace',
        'updatedAt': nowIso,
        'history': normalizedHistory,
      });

      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.userId;
        if (userId != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await _syncPendingLearningRecord(prefs, userId, problem.id);
            print(
              'Successfully saved learning history for problem ${problem.id}',
            );
          } catch (e, stackTrace) {
            print(
              'Error saving history to Firestore (continuing with local save): $e',
            );
            print('Stack trace: $stackTrace');
            // Firestoreエラー時はローカルのみで動作継続
          }
        } else {
          print('Warning: User ID is null, skipping Firestore sync');
        }
      } else {
        print('User not authenticated, skipping Firestore sync');
      }

      return true;
    } catch (e) {
      print('Error saving learning history: $e');
      return false;
    }
  }

  /// チュートリアル用の学習履歴を保存（無課金でも保存される例外処理）
  /// 通常のsaveLearningHistoryと同様だが、履歴管理の有効性チェックをスキップ
  static Future<bool> saveTutorialLearningHistory(
    dynamic problem,
    List<Map<String, dynamic>> history,
  ) async {
    return saveLearningHistory(problem, history);
  }

  /// 学習記録をクリアする
  /// 空の履歴をローカルとクラウドへ保存し、次回同期で古い記録が復活しないようにする
  static Future<bool> clearLearningHistory(dynamic problem) async {
    try {
      final nowIso = DateTime.now().toIso8601String();
      await _enqueuePendingLearningOperation(problem.id, {
        'kind': 'clear',
        'updatedAt': nowIso,
      });

      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.userId;
        if (userId != null) {
          final prefs = await SharedPreferences.getInstance();
          await _syncPendingLearningRecord(prefs, userId, problem.id);
        }
      }
      print('Successfully cleared learning history for problem ${problem.id}');
      return true;
    } catch (e) {
      print('Error clearing learning history: $e');
      return false;
    }
  }

  // ============================================================================
  // ガチャ管理（シンプル版）
  // ============================================================================

  /// ガチャ設定を保存
  static Future<bool> saveGachaSettings(
    String gachaType,
    Map<String, dynamic> settings,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nextSettings = _getDefaultGachaSettings()..addAll(settings);
      final nowIso = DateTime.now().toIso8601String();
      nextSettings['updatedAt'] = nowIso;
      nextSettings['lastUpdated'] = nowIso;
      await _savePendingSettingOperation(
        prefs,
        _pendingGachaSettingsScope(gachaType),
        _buildPendingSettingReplaceOperation(
          nextSettings,
          updatedAt: nowIso,
        ),
        invalidateCache: () => _invalidateSettingsCaches(gachaType: gachaType),
      );
      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.userId;
        if (userId != null) {
          unawaited(_syncPendingGachaSettings(prefs, userId, gachaType));
        }
      }
      return true;
    } catch (e) {
      print('Error saving gacha settings: $e');
      return false;
    }
  }

  /// ガチャ設定を取得
  static Future<Map<String, dynamic>> getGachaSettings(String gachaType) async {
    try {
      return _resolveDisplayGachaSettings(gachaType);
    } catch (e) {
      print('Error getting gacha settings: $e');
      return _getDefaultGachaSettings();
    }
  }

  /// デフォルトガチャ設定
  static Map<String, dynamic> _getDefaultGachaSettings() {
    return {
      'filterMode': 'exclude_solved_ge1',
      'slotLevels': [0, 1, 2],
      'rollCount': 0,
      'lastRollTime': null,
      'aggregationMode': 0, // AggregationMode.latest1 (デフォルト)
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  // ============================================================================
  // データ移行管理
  // ============================================================================

  // ============================================================================
  // 将来の拡張用メソッド（プレースホルダー）
  // ============================================================================

  /// 新しいガチャタイプの設定を保存
  static Future<bool> saveNewGachaType(
    String gachaType,
    Map<String, dynamic> settings,
  ) async {
    // 将来の拡張用
    return await saveGachaSettings(gachaType, settings);
  }

  /// ユーザー設定を保存（将来の拡張用）
  static Future<bool> saveUserSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await _resolveDisplayUserSettings();
      final nextSettings = Map<String, dynamic>.from(current)..addAll(settings);
      final nowIso = DateTime.now().toIso8601String();
      nextSettings['lastUpdated'] = nowIso;
      await _savePendingSettingOperation(
        prefs,
        _pendingUserSettingsScope,
        _buildPendingSettingReplaceOperation(
          nextSettings,
          updatedAt: nowIso,
        ),
        invalidateCache: _invalidateSettingsCaches,
      );
      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.userId;
        if (userId != null) {
          unawaited(_syncPendingUserSettings(prefs, userId));
        }
      }
      return true;
    } catch (e) {
      print('Error saving user settings: $e');
      return false;
    }
  }

  /// ユーザー設定を取得（将来の拡張用）
  static Future<Map<String, dynamic>> getUserSettings() async {
    try {
      return _resolveDisplayUserSettings();
    } catch (e) {
      print('Error getting user settings: $e');
      return {};
    }
  }

  // ============================================================================
  // データの一括操作
  // ============================================================================

  /// 全データをエクスポート
  static Future<Map<String, dynamic>> exportAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final appKeys = allKeys
          .where((key) => key.startsWith(_namespace))
          .toList();

      final Map<String, dynamic> exportData = {};
      for (final key in appKeys) {
        final value = prefs.getString(key);
        if (value != null) {
          exportData[key] = value;
        }
      }

      return exportData;
    } catch (e) {
      print('Error exporting data: $e');
      return {};
    }
  }

  /// 全データをクリア
  static Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final appKeys = allKeys
          .where((key) => key.startsWith(_namespace))
          .toList();

      for (final key in appKeys) {
        await prefs.remove(key);
      }

      return true;
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }

  /// デバッグ用：全キーを表示
  static Future<void> debugPrintAllKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final appKeys = allKeys
          .where((key) => key.startsWith(_namespace))
          .toList();

      print('=== SimpleDataManager Keys ===');
      for (final key in appKeys) {
        print('  $key');
      }
      print('===============================');
    } catch (e) {
      print('Error printing keys: $e');
    }
  }

  // ============================================================================
  // アカウント切り替え管理
  // ============================================================================

  /// 最後にログインしたユーザーIDを取得
  static Future<String?> getLastUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastUserIdKey);
    } catch (e) {
      print('Error getting last user ID: $e');
      return null;
    }
  }

  /// 最後にログインしたユーザーIDを保存
  static Future<void> setLastUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUserIdKey, userId);
    } catch (e) {
      print('Error setting last user ID: $e');
    }
  }

  /// アカウント切り替えを検知（前のユーザーIDと現在のユーザーIDを比較）
  static Future<bool> isAccountSwitched() async {
    try {
      final lastUserId = await getLastUserId();
      final currentUserId = FirebaseAuthService.userId;

      // 前のユーザーIDが存在し、現在のユーザーIDと異なる場合はアカウント切り替え
      if (lastUserId != null &&
          currentUserId != null &&
          lastUserId != currentUserId) {
        print('Account switched detected: $lastUserId -> $currentUserId');
        return true;
      }

      return false;
    } catch (e) {
      print('Error checking account switch: $e');
      return false;
    }
  }

  /// アカウント固有のローカルデータをクリア（学習記録、設定など）
  /// バージョン情報や移行フラグは保持
  static Future<bool> clearAccountSpecificData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      // クリアするキーのパターン
      final patternsToClear = [
        '$_namespace/learning/', // 学習記録
        '$_namespace/gacha/', // ガチャ設定
        '$_namespace/user_settings', // ユーザー設定
        '$_namespace/firestore_sync_completed_', // 同期完了フラグ
      ];

      // 保持するキー（バージョン情報、最後のユーザーID）
      final keysToKeep = [_versionKey, _lastUserIdKey];

      int clearedCount = 0;

      for (final key in allKeys) {
        // 保持するキーはスキップ
        if (keysToKeep.contains(key)) {
          continue;
        }

        // クリア対象のパターンに一致するキーを削除
        bool shouldClear = false;
        for (final pattern in patternsToClear) {
          if (key.startsWith(pattern)) {
            shouldClear = true;
            break;
          }
        }

        // その他の設定キーもクリア（integral_gacha_exclusion_modeなど）
        if (!shouldClear && key.startsWith(_namespace)) {
          // 名前空間内のその他のキーもクリア（ただし、保持するキーは除く）
          if (!keysToKeep.contains(key)) {
            shouldClear = true;
          }
        }

        if (shouldClear) {
          await prefs.remove(key);
          clearedCount++;
        }
      }

      _invalidateLearningCaches();
      _invalidateSettingsCaches();
      print('Cleared $clearedCount account-specific data keys');
      return true;
    } catch (e) {
      print('Error clearing account-specific data: $e');
      return false;
    }
  }

  /// アカウント切り替え時のデータ同期処理
  /// 前のアカウントの pending ローカルデータをクリアし、新しいアカウントへ持ち越さない
  static Future<void> syncOnAccountSwitch() async {
    try {
      final currentUserId = FirebaseAuthService.userId;
      if (currentUserId == null) {
        print('No current user, skipping account switch sync');
        return;
      }
      await _withCloudSyncIndicator(() async {
        // 前アカウントのローカルデータを新アカウントへ混ぜない
        await clearAccountSpecificData();
        // 現在のユーザーIDを保存
        await setLastUserId(currentUserId);
      });

      print('Account switch sync completed');
    } catch (e) {
      print('Error in account switch sync: $e');
    }
  }

  // ============================================================================
  // 無料で履歴管理可能なガチャ選択機能
  // ============================================================================

  static const String _selectedFreeGachasKey =
      '$_namespace/selected_free_gachas';

  static Future<bool> saveOtherSettingValue(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nowIso = DateTime.now().toIso8601String();
      await _savePendingSettingOperation(
        prefs,
        _pendingOtherSettingScope(key),
        _buildPendingSettingReplaceOperation(value, updatedAt: nowIso),
        invalidateCache: () => _invalidateSettingsCaches(otherSettingKey: key),
      );
      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.userId;
        if (userId != null) {
          unawaited(_syncPendingOtherSetting(prefs, userId, key));
        }
      }
      return true;
    } catch (e) {
      print('Error saving other setting $key: $e');
      return false;
    }
  }

  /// 選択された無料ガチャのリストを取得
  static Future<List<String>> getSelectedFreeGachas() async {
    try {
      final value = await getOtherSettingValue(
        _selectedFreeGachasKey,
        legacyDecoder: _decodeSelectedFreeGachasLegacyValue,
      );
      return _normalizeStringList(value, maxLength: 2);
    } catch (e) {
      print('Error getting selected free gachas: $e');
      return [];
    }
  }

  /// 選択された無料ガチャを保存
  static Future<bool> saveSelectedFreeGachas(List<String> prefsPrefixes) async {
    try {
      if (prefsPrefixes.length > 2) {
        print(
          'Warning: More than 2 gachas selected. Only first 2 will be saved.',
        );
        prefsPrefixes = prefsPrefixes.take(2).toList();
      }
      await saveOtherSettingValue(_selectedFreeGachasKey, prefsPrefixes);
      print('Saved selected free gachas: $prefsPrefixes');
      return true;
    } catch (e) {
      print('Error saving selected free gachas: $e');
      return false;
    }
  }

  /// 既に無料ガチャが選択済みかどうかを確認
  static Future<bool> hasSelectedFreeGachas() async {
    try {
      final selected = await getSelectedFreeGachas();
      return selected.isNotEmpty;
    } catch (e) {
      print('Error checking if free gachas are selected: $e');
      return false;
    }
  }

  /// 指定されたガチャが無料で履歴管理可能かどうかを確認
  /// 常にtrueを返す（すべてのガチャで履歴管理が可能）
  static Future<bool> isFreeGachaEnabled(String prefsPrefix) async {
    // すべてのガチャで履歴管理が可能
    return true;
  }

  /// 学習履歴オプションの購入状態を確認（RevenueCatServiceのラッパー）
  static Future<bool> isLearningHistoryOptionPurchased() async {
    try {
      return await RevenueCatService.isLearningHistoryOptionPurchased();
    } catch (e) {
      print('Error checking learning history option purchase: $e');
      return false;
    }
  }
}
