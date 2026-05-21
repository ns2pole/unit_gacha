// lib/services/problems/simple_data_manager.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/math_problem.dart';
import '../../models/learning_status.dart';
import '../../pages/common/problem_status.dart';
import '../auth/firebase_auth_service.dart';
import '../auth/firestore_learning_service.dart';
import '../auth/firestore_settings_service.dart';
import '../../managers/app_logger.dart';

/// シンプルで拡張可能なデータ管理システム
/// 現在の必要最小限のデータ + 将来の拡張に対応
class SimpleDataManager {
  /// Local storage prefix. Intentionally unchanged from the joymath fork so
  /// existing installs keep their SharedPreferences data without migration.
  static const String _namespace = 'joymath_simple';
  static const String _version = '1.0.0';
  static const String _versionKey = '$_namespace/version';
  static const String _lastUserIdKey = '$_namespace/last_user_id';

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

  /// 端末内の学習記録を読む（SharedPreferences の JSON を正本とする）
  static Future<Map<String, dynamic>> _loadLocalLearningRecord(
    SharedPreferences prefs,
    String problemId,
  ) async {
    final raw = prefs.getString(_legacyLearningKey(problemId));
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          return _buildLearningRecordData(
            problemId: problemId,
            history: map['history'],
            fallbackUpdatedAt: map['lastUpdated'] as String?,
          );
        }
      } catch (_) {}
    }

    // 旧 pending キューだけ残っている場合は取り込んでから正本へ移す
    final pending = await _loadPendingLearningOperations(prefs, problemId);
    if (pending.isEmpty) {
      return _buildLearningRecordData(problemId: problemId, history: const []);
    }
    final history = _applyPendingLearningOperations(const [], pending);
    final record = _buildLearningRecordData(
      problemId: problemId,
      history: history,
    );
    await _saveLocalLearningRecord(prefs, problemId, record, notify: false);
    return record;
  }

  /// 端末内の学習記録を書く（読み取りと同じキーへ直書き）
  static Future<void> _saveLocalLearningRecord(
    SharedPreferences prefs,
    String problemId,
    Map<String, dynamic> data, {
    bool notify = true,
  }) async {
    final record = _buildLearningRecordData(
      problemId: problemId,
      history: data['history'],
      fallbackUpdatedAt: data['lastUpdated'] as String?,
    );
    await prefs.setString(_legacyLearningKey(problemId), json.encode(record));
    await prefs.remove(_pendingLearningOpsKey(problemId));

    final history = _normalizeHistoryList(
      record['history'],
      maxEntries: learningHistoryRetentionCount,
    );
    _learningDataCache[problemId] = Map<String, dynamic>.from(record);
    _learningHistoryCache[problemId] = List<Map<String, dynamic>>.from(history);
    if (notify) _notifyLearningDataChanged();
  }

  static List<Map<String, dynamic>> _mergeHistoryLists(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    return _normalizeHistoryList(
      [...a, ...b],
      maxEntries: learningHistoryRetentionCount,
    );
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
    final cached = _learningDataCache[problemId];
    if (cached != null) return Map<String, dynamic>.from(cached);

    final prefs = await SharedPreferences.getInstance();
    final local = await _loadLocalLearningRecord(prefs, problemId);
    var resolvedHistory =
        local['history'] as List<Map<String, dynamic>>? ?? const [];

    final userId = FirebaseAuthService.userId;
    if (FirebaseAuthService.isAuthenticated && userId != null) {
      try {
        final cloudData = await _fetchCloudLearningRecord(userId, problemId);
        final cloudHistory =
            cloudData?['history'] as List<Map<String, dynamic>>? ?? const [];
        resolvedHistory = _mergeHistoryLists(resolvedHistory, cloudHistory);
      } catch (_) {}
    }

    final resolved = _buildLearningRecordData(
      problemId: problemId,
      history: resolvedHistory,
    );
    _learningDataCache[problemId] = Map<String, dynamic>.from(resolved);
    _learningHistoryCache[problemId] = List<Map<String, dynamic>>.from(
      resolvedHistory,
    );
    return Map<String, dynamic>.from(resolved);
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

    await _saveLocalLearningRecord(
      prefs,
      problemId,
      mergedRecord,
      notify: true,
    );
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

  static DateTime? _pendingOperationTime(Map<String, dynamic>? operation) =>
      _tryParseDateTime(operation?['updatedAt']);

  static DateTime? _mapSettingTime(Map<String, dynamic>? map) =>
      _tryParseDateTime(map?['lastUpdated'] ?? map?['updatedAt']);

  /// 端末(pending)とクラウドのうち updatedAt が新しい方だけ採用する
  static bool _isPendingNewerThanCloud({
    required Map<String, dynamic>? pending,
    required DateTime? cloudUpdatedAt,
  }) {
    if (pending == null) return false;
    final pendingTime = _pendingOperationTime(pending);
    if (cloudUpdatedAt == null) return true;
    if (pendingTime == null) return false;
    return pendingTime.isAfter(cloudUpdatedAt);
  }

  static Map<String, dynamic> _pickLatestGachaSettings({
    Map<String, dynamic>? cloud,
    required Map<String, dynamic>? pending,
  }) {
    final defaults = _getDefaultGachaSettings();
    if (pending == null) {
      return cloud == null
          ? Map<String, dynamic>.from(defaults)
          : (defaults..addAll(cloud));
    }

    final cloudTime = _mapSettingTime(cloud);
    if (!_isPendingNewerThanCloud(pending: pending, cloudUpdatedAt: cloudTime)) {
      return cloud == null
          ? Map<String, dynamic>.from(defaults)
          : (defaults..addAll(cloud));
    }

    final resolved = _applyPendingSettingOperation(defaults, pending);
    final out = Map<String, dynamic>.from(defaults);
    if (resolved is Map) {
      out.addAll(Map<String, dynamic>.from(resolved));
    }
    return out;
  }

  static Map<String, dynamic> _pickLatestUserSettings({
    Map<String, dynamic>? cloud,
    required Map<String, dynamic>? pending,
  }) {
    if (pending == null) {
      return cloud == null ? <String, dynamic>{} : Map<String, dynamic>.from(cloud);
    }

    final cloudTime = _mapSettingTime(cloud);
    if (!_isPendingNewerThanCloud(pending: pending, cloudUpdatedAt: cloudTime)) {
      return cloud == null ? <String, dynamic>{} : Map<String, dynamic>.from(cloud);
    }

    final resolved = _applyPendingSettingOperation(const {}, pending);
    return resolved is Map
        ? Map<String, dynamic>.from(resolved)
        : <String, dynamic>{};
  }

  static dynamic _pickLatestOtherSetting({
    required dynamic cloudValue,
    required DateTime? cloudUpdatedAt,
    required Map<String, dynamic>? pending,
  }) {
    if (pending == null) return _cloneJsonValue(cloudValue);
    if (!_isPendingNewerThanCloud(
      pending: pending,
      cloudUpdatedAt: cloudUpdatedAt,
    )) {
      return _cloneJsonValue(cloudValue);
    }
    return _applyPendingSettingOperation(null, pending);
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

    final resolved = _pickLatestGachaSettings(cloud: cloudData, pending: pending);
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

    final resolved = _pickLatestUserSettings(cloud: cloudData, pending: pending);
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
    DateTime? cloudUpdatedAt;
    final userId = FirebaseAuthService.userId;
    if (FirebaseAuthService.isAuthenticated && userId != null) {
      try {
        cloudValue = await FirestoreSettingsService.getOtherSetting(
          userId: userId,
          key: key,
        );
        cloudUpdatedAt = await FirestoreSettingsService.getOtherSettingUpdatedAt(
          userId: userId,
          key: key,
        );
      } catch (_) {
        cloudValue = null;
        cloudUpdatedAt = null;
      }
    }

    final resolved = _pickLatestOtherSetting(
      cloudValue: cloudValue,
      cloudUpdatedAt: cloudUpdatedAt,
      pending: pending,
    );
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

    Map<String, dynamic>? cloud;
    try {
      cloud = await _fetchCloudGachaSettings(userId, gachaType);
    } catch (_) {
      cloud = null;
    }
    final settings = _pickLatestGachaSettings(cloud: cloud, pending: pending);
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

    Map<String, dynamic>? cloud;
    try {
      cloud = await FirestoreSettingsService.getUserSettings(userId: userId);
    } catch (_) {
      cloud = null;
    }
    final settings = _pickLatestUserSettings(cloud: cloud, pending: pending);
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

    dynamic cloudValue;
    DateTime? cloudUpdatedAt;
    try {
      cloudValue = await FirestoreSettingsService.getOtherSetting(
        userId: userId,
        key: key,
      );
      cloudUpdatedAt = await FirestoreSettingsService.getOtherSettingUpdatedAt(
        userId: userId,
        key: key,
      );
    } catch (_) {
      cloudValue = null;
      cloudUpdatedAt = null;
    }
    final value = _pickLatestOtherSetting(
      cloudValue: cloudValue,
      cloudUpdatedAt: cloudUpdatedAt,
      pending: pending,
    );
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

      // 旧ランキング用イベントキュー（削除済み機能）の残骸を掃除
      await prefs.remove('$_namespace/unit_gacha_attempt_events_queue_v1');
      await prefs.remove('$_namespace/unit_gacha_attempt_events_last_sync_v1');

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

  /// 端末内の学習記録をクラウドへマージして保存（ログイン・アカウント切替時）
  static Future<void> _pushLocalLearningRecordsToFirestore(
    SharedPreferences prefs,
    String userId,
  ) async {
    final prefix = '$_namespace/learning/';
    var changed = false;

    for (final key in prefs.getKeys()) {
      if (!key.startsWith(prefix)) continue;
      final problemId = key.substring(prefix.length);
      try {
        final local = await _loadLocalLearningRecord(prefs, problemId);
        final localHistory =
            local['history'] as List<Map<String, dynamic>>? ?? const [];
        if (localHistory.isEmpty) continue;

        final cloudData = await _fetchCloudLearningRecord(userId, problemId);
        final cloudHistory =
            cloudData?['history'] as List<Map<String, dynamic>>? ?? const [];
        final mergedRecord = _buildLearningRecordData(
          problemId: problemId,
          history: _mergeHistoryLists(localHistory, cloudHistory),
          fallbackUpdatedAt:
              cloudData?['lastUpdated'] as String? ??
              local['lastUpdated'] as String?,
        );

        final success = await FirestoreLearningService.saveLearningRecord(
          userId: userId,
          problemId: problemId,
          data: mergedRecord,
        );
        if (!success) continue;

        await _saveLocalLearningRecord(
          prefs,
          problemId,
          mergedRecord,
          notify: false,
        );
        changed = true;
      } catch (e) {
        print('Error pushing local learning record $problemId: $e');
      }
    }

    if (changed) _notifyLearningDataChanged();
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
        print('Starting local learning sync for user: $userId');
        final prefs = await SharedPreferences.getInstance();
        await _pushLocalLearningRecordsToFirestore(prefs, userId);

        print('Starting pending learning log sync for user: $userId');
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

      final prefs = await SharedPreferences.getInstance();
      final nowIso = DateTime.now().toIso8601String();
      final local = await _loadLocalLearningRecord(prefs, problem.id);
      final history = List<Map<String, dynamic>>.from(
        _normalizeHistoryList(
          local['history'],
          maxEntries: learningHistoryRetentionCount,
        ),
      );
      history.add({
        'status': statusKey,
        'time': nowIso,
        'updatedAt': nowIso,
        if (byCalculator) 'byCalculator': true,
      });
      final next = _buildLearningRecordData(
        problemId: problem.id,
        history: history,
      );
      await _saveLocalLearningRecord(prefs, problem.id, next);

      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.userId;
        if (userId != null) {
          try {
            await FirestoreLearningService.saveLearningRecord(
              userId: userId,
              problemId: problem.id,
              data: next,
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
    final cached = _learningHistoryCache[problemId];
    if (cached != null) return cached;

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
          newStatus = 'solved';
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

    _learningHistoryCache[problemId] = migratedHistory;
    return migratedHistory;
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
      final prefs = await SharedPreferences.getInstance();
      final next = _buildLearningRecordData(
        problemId: problem.id,
        history: normalizedHistory,
      );
      await _saveLocalLearningRecord(prefs, problem.id, next);

      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.userId;
        if (userId != null) {
          try {
            await FirestoreLearningService.saveLearningRecord(
              userId: userId,
              problemId: problem.id,
              data: next,
            );
          } catch (e, stackTrace) {
            print(
              'Error saving history to Firestore (continuing with local save): $e',
            );
            print('Stack trace: $stackTrace');
          }
        }
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
      final prefs = await SharedPreferences.getInstance();
      final empty = _buildLearningRecordData(
        problemId: problem.id,
        history: const [],
      );
      await _saveLocalLearningRecord(prefs, problem.id, empty);

      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.userId;
        if (userId != null) {
          await FirestoreLearningService.saveLearningRecord(
            userId: userId,
            problemId: problem.id,
            data: empty,
          );
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
  static Future<bool> clearAccountSpecificData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      const keysToKeep = [_versionKey, _lastUserIdKey];
      const patternsToClear = [
        '$_namespace/learning/',
        '$_namespace/gacha/',
        '$_namespace/user_settings',
        '$_namespace/settings_pending/',
        '$_namespace/firestore_sync_completed_',
      ];

      for (final key in allKeys) {
        if (keysToKeep.contains(key)) continue;
        var shouldClear = false;
        for (final pattern in patternsToClear) {
          if (key.startsWith(pattern)) {
            shouldClear = true;
            break;
          }
        }
        if (!shouldClear && key.startsWith(_namespace)) {
          shouldClear = true;
        }
        if (shouldClear) await prefs.remove(key);
      }

      _invalidateLearningCaches();
      _invalidateSettingsCaches();
      return true;
    } catch (e) {
      print('Error clearing account-specific data: $e');
      return false;
    }
  }

  /// ログイン中アカウントのクラウド学習履歴を端末へ復元
  static Future<void> _hydrateLocalLearningRecordsFromCloud() async {
    final userId = FirebaseAuthService.userId;
    if (userId == null) return;

    try {
      final remote = await FirestoreLearningService.getAllLearningRecords(
        userId: userId,
      );
      if (remote.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      for (final entry in remote.entries) {
        final cloud = entry.value;
        final record = _buildLearningRecordData(
          problemId: entry.key,
          history: cloud['history'],
          fallbackUpdatedAt: cloud['lastUpdated'] as String?,
        );
        await _saveLocalLearningRecord(
          prefs,
          entry.key,
          record,
          notify: false,
        );
      }
      _notifyLearningDataChanged();
    } catch (e) {
      print('Error hydrating learning records from cloud: $e');
    }
  }

  /// アカウント切替時: 前アカウントの端末データを消し、新アカウントのクラウドから復元
  static Future<void> syncOnAccountSwitch() async {
    await clearAccountSpecificData();
    await _hydrateLocalLearningRecordsFromCloud();
    final currentUserId = FirebaseAuthService.userId;
    if (currentUserId != null) {
      await setLastUserId(currentUserId);
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

  /// 学習履歴オプションの購入状態。現状は常に利用可能として扱う。
  static Future<bool> isLearningHistoryOptionPurchased() async {
    return true;
  }
}
