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

  static bool _isRecommendCategory(UnitCategory c) =>
      c == UnitCategory.mechanics || c == UnitCategory.electromagnetism;

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

  static String _learningKey(String problemId) =>
      '$_namespace/learning/$problemId';

  static bool get _isCloudAuthoritativeRead =>
      kIsWeb && FirebaseAuthService.isAuthenticated;

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

    final dt = _tryParseDateTime(raw['time']);
    final normalized = <String, dynamic>{
      'status': status,
      'time': dt?.toIso8601String(),
    };
    final byCalc = raw['byCalculator'];
    if (byCalc is bool) {
      normalized['byCalculator'] = byCalc;
    }
    return normalized;
  }

  static List<Map<String, dynamic>> _normalizeHistoryList(
    dynamic historyAny, {
    int? maxEntries,
  }) {
    final byTime = <String, Map<String, dynamic>>{};
    if (historyAny is List) {
      for (final raw in historyAny) {
        final normalized = _normalizeHistoryRecord(raw);
        if (normalized == null) continue;
        final time = normalized['time'] as String?;
        final status = normalized['status'] as String? ?? 'none';
        if (time == null || time.isEmpty || status == 'none') {
          continue;
        }

        final prev = byTime[time];
        if (prev == null) {
          byTime[time] = normalized;
          continue;
        }

        final prevByCalc = prev['byCalculator'] == true;
        final nextByCalc = normalized['byCalculator'] == true;
        if (!prevByCalc && nextByCalc) {
          byTime[time] = normalized;
        }
      }
    }

    final out = byTime.values.toList()
      ..sort((a, b) {
        final timeA = _tryParseDateTime(a['time']);
        final timeB = _tryParseDateTime(b['time']);
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

  static String _deriveMergedLastUpdated({
    required List<Map<String, dynamic>> history,
    Map<String, dynamic>? localData,
    Map<String, dynamic>? remoteData,
  }) {
    DateTime? newest;

    final historyTime = history.isNotEmpty
        ? _tryParseDateTime(history.last['time'])
        : null;
    if (historyTime != null) newest = historyTime;

    final localUpdated = _tryParseDateTime(localData?['lastUpdated']);
    if (localUpdated != null &&
        (newest == null || localUpdated.isAfter(newest))) {
      newest = localUpdated;
    }

    final remoteUpdated = _tryParseDateTime(remoteData?['lastUpdated']);
    if (remoteUpdated != null &&
        (newest == null || remoteUpdated.isAfter(newest))) {
      newest = remoteUpdated;
    }

    return (newest ?? DateTime.now()).toIso8601String();
  }

  static Map<String, dynamic> _mergeLearningRecordData({
    required String problemId,
    Map<String, dynamic>? localData,
    Map<String, dynamic>? remoteData,
    bool preferRemoteMetadata = false,
  }) {
    final localHistory = _normalizeHistoryList(
      localData?['history'],
      maxEntries: learningHistoryRetentionCount,
    );
    final remoteHistory = _normalizeHistoryList(
      remoteData?['history'],
      maxEntries: learningHistoryRetentionCount,
    );
    final mergedHistory = _normalizeHistoryList([
      ...localHistory,
      ...remoteHistory,
    ], maxEntries: learningHistoryRetentionCount);

    final localUpdated = _tryParseDateTime(localData?['lastUpdated']);
    final remoteUpdated = _tryParseDateTime(remoteData?['lastUpdated']);

    Map<String, dynamic>? base;
    if (localData != null && remoteData != null) {
      if (preferRemoteMetadata) {
        base = Map<String, dynamic>.from(remoteData);
      } else if (remoteUpdated != null &&
          (localUpdated == null || remoteUpdated.isAfter(localUpdated))) {
        base = Map<String, dynamic>.from(remoteData);
      } else {
        base = Map<String, dynamic>.from(localData);
      }
    } else if (remoteData != null) {
      base = Map<String, dynamic>.from(remoteData);
    } else if (localData != null) {
      base = Map<String, dynamic>.from(localData);
    } else {
      base = <String, dynamic>{};
    }

    base['problemId'] = problemId;
    base['history'] = mergedHistory;
    base['latestStatus'] = _deriveLatestStatus(mergedHistory);
    base['lastUpdated'] = _deriveMergedLastUpdated(
      history: mergedHistory,
      localData: localData,
      remoteData: remoteData,
    );
    return base;
  }

  static bool _learningRecordContentsEqual(
    Map<String, dynamic>? a,
    Map<String, dynamic>? b,
  ) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;

    final historyA = _normalizeHistoryList(
      a['history'],
      maxEntries: learningHistoryRetentionCount,
    );
    final historyB = _normalizeHistoryList(
      b['history'],
      maxEntries: learningHistoryRetentionCount,
    );
    if (json.encode(historyA) != json.encode(historyB)) {
      return false;
    }

    final latestA = _deriveLatestStatus(historyA);
    final latestB = _deriveLatestStatus(historyB);
    return latestA == latestB;
  }

  static bool _learningRecordFullyEqual(
    Map<String, dynamic>? a,
    Map<String, dynamic>? b,
  ) {
    if (!_learningRecordContentsEqual(a, b)) return false;
    return _tryParseDateTime(a?['lastUpdated']) ==
        _tryParseDateTime(b?['lastUpdated']);
  }

  static Future<Map<String, dynamic>?> _loadLearningRecordById(
    SharedPreferences prefs,
    String problemId,
  ) async {
    final dataString = prefs.getString(_learningKey(problemId));
    if (dataString == null || dataString.isEmpty) return null;
    try {
      final decoded = json.decode(dataString);
      if (decoded is Map<String, dynamic>) {
        return Map<String, dynamic>.from(decoded);
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> _saveLearningRecordById(
    SharedPreferences prefs,
    String problemId,
    Map<String, dynamic> data, {
    bool notify = true,
  }) async {
    final existing = await _loadLearningRecordById(prefs, problemId);
    final changed = !_learningRecordFullyEqual(existing, data);
    if (!changed) return false;

    final encoded = json.encode(data);
    await prefs.setString(_learningKey(problemId), encoded);
    _learningDataCache[problemId] = Map<String, dynamic>.from(data);
    _learningHistoryCache[problemId] = _normalizeHistoryList(
      data['history'],
      maxEntries: learningHistoryRetentionCount,
    );
    if (notify) _notifyLearningDataChanged();
    return true;
  }

  static Future<Map<String, dynamic>?> _reconcileLearningRecordForProblem({
    required SharedPreferences prefs,
    required String userId,
    required String problemId,
    Map<String, dynamic>? localData,
    bool pushMergedToFirestore = false,
    bool preferRemoteMetadata = false,
  }) async {
    Map<String, dynamic>? remoteData;
    try {
      remoteData = await FirestoreLearningService.getLearningRecord(
        userId: userId,
        problemId: problemId,
      );
    } catch (_) {}

    final merged = _mergeLearningRecordData(
      problemId: problemId,
      localData: localData,
      remoteData: remoteData,
      preferRemoteMetadata: preferRemoteMetadata,
    );

    final localChanged = await _saveLearningRecordById(
      prefs,
      problemId,
      merged,
      notify: false,
    );

    if (pushMergedToFirestore &&
        !_learningRecordContentsEqual(remoteData, merged)) {
      await FirestoreLearningService.saveLearningRecord(
        userId: userId,
        problemId: problemId,
        data: merged,
      );
    }

    if (localChanged) {
      _notifyLearningDataChanged();
    }
    return merged;
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

      // 認証済みユーザーの場合、Firestoreと再同期
      if (FirebaseAuthService.isAuthenticated) {
        await _withCloudSyncIndicator(() async {
          await _syncFromFirestore(pushMergedToFirestore: true);
          // オフライン時に溜めた解答イベントがあれば、ここで送る（UIをブロックしない範囲で）
          // 失敗しても次回同期（クラウド同期ボタン）で再試行される
          unawaited(syncUnitGachaAttemptEventsToFirestore().then((_) {}));
        });
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

  /// Firestoreからデータを同期（認証済みユーザー用）
  static Future<void> _syncFromFirestore({
    bool pushMergedToFirestore = true,
  }) async {
    try {
      final userId = FirebaseAuthService.userId;
      if (userId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final syncKey = '$_namespace/firestore_sync_completed_$userId';

      // 全学習記録を取得（タイムアウト付き）
      Map<String, Map<String, dynamic>> firestoreRecords;
      try {
        firestoreRecords =
            await FirestoreLearningService.getAllLearningRecords(
              userId: userId,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print(
                  '⚠️ Timeout getting learning records from Firestore for user: $userId',
                );
                return <String, Map<String, dynamic>>{};
              },
            );
      } catch (e) {
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('permission') ||
            errorStr.contains('permission-denied')) {
          print(
            '⚠️ Permission denied getting learning records from Firestore for user: $userId',
          );
          print(
            '⚠️ Firestoreセキュリティルールを確認してください。FIRESTORE_SECURITY_RULES.mdを参照してください。',
          );
          // 権限エラーの場合は設定のみ同期を試みる
          await _syncSettingsFromFirestore(userId);
          return;
        }
        print(
          'Error getting learning records from Firestore for user: $userId - $e',
        );
        firestoreRecords = {};
      }

      final localProblemIds = prefs
          .getKeys()
          .where(
            (key) =>
                key.startsWith('$_namespace/learning/') &&
                key != '$_namespace/learning',
          )
          .map((key) => key.replaceFirst('$_namespace/learning/', ''));
      final allProblemIds = <String>{
        ...firestoreRecords.keys,
        ...localProblemIds,
      };

      var hasLocalChanges = false;
      for (final problemId in allProblemIds) {
        final localData = await _loadLearningRecordById(prefs, problemId);
        final firestoreData = firestoreRecords[problemId];
        final mergedData = _mergeLearningRecordData(
          problemId: problemId,
          localData: localData,
          remoteData: firestoreData,
          preferRemoteMetadata: _isCloudAuthoritativeRead,
        );

        final localChanged = await _saveLearningRecordById(
          prefs,
          problemId,
          mergedData,
          notify: false,
        );
        hasLocalChanges = hasLocalChanges || localChanged;

        if (pushMergedToFirestore &&
            !_learningRecordContentsEqual(firestoreData, mergedData)) {
          await FirestoreLearningService.saveLearningRecord(
            userId: userId,
            problemId: problemId,
            data: mergedData,
          );
        }
      }

      // 設定を同期
      await _syncSettingsFromFirestore(userId);

      // 同期完了時刻を記録
      await prefs.setString(syncKey, DateTime.now().toIso8601String());

      AppLogger.success('Firestoreからのデータ同期が完了しました');
      if (hasLocalChanges) {
        _invalidateLearningCaches();
      }
    } catch (e) {
      AppLogger.error('Firestoreからのデータ同期に失敗しました', error: e);
      // エラー時も処理を継続
    }
  }

  /// Firestoreから設定を同期（内部メソッド）
  static Future<void> _syncSettingsFromFirestore(String userId) async {
    try {
      // 認証状態を確認
      final isAuthenticated = FirebaseAuthService.isAuthenticated;
      final currentUserId = FirebaseAuthService.userId;

      if (!isAuthenticated) {
        print('⚠️ Firestore設定同期をスキップ: ユーザーが認証されていません');
        return;
      }

      if (currentUserId != userId) {
        print(
          '⚠️ Firestore設定同期をスキップ: ユーザーIDが一致しません (リクエスト: $userId, 現在: $currentUserId)',
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      AppLogger.subsection('設定の同期開始', showNumber: false);
      AppLogger.info('Firestoreから設定を同期中', details: 'ユーザーID: $userId');

      // 全設定を取得（タイムアウト付き）
      Map<String, dynamic> allSettings;
      try {
        allSettings =
            await FirestoreSettingsService.getAllSettings(
              userId: userId,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                AppLogger.warning(
                  '設定の同期がタイムアウトしました',
                  details: '10秒以内に完了しませんでした',
                );
                return <String, dynamic>{};
              },
            );
      } catch (e) {
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('permission') ||
            errorStr.contains('permission-denied')) {
          AppLogger.warning(
            '設定の同期が権限エラーで失敗しました',
            details:
                'Firestoreセキュリティルールを確認してください。FIRESTORE_SECURITY_RULES.mdを参照してください。',
          );
          return; // 権限エラーの場合は早期に処理を停止
        }
        AppLogger.error('設定の取得に失敗しました', error: e);
        allSettings = {};
      }

      // 権限エラーが発生した場合は早期に処理を停止
      if (allSettings.isEmpty) {
        AppLogger.warning('設定の同期をスキップしました', details: '空の設定が返されました（権限エラーの可能性）');
        return;
      }

      // ガチャ設定を同期
      final gachaSettings =
          allSettings['gacha_settings'] as Map<String, Map<String, dynamic>>?;
      if (gachaSettings != null) {
        for (final entry in gachaSettings.entries) {
          final gachaType = entry.key;
          final firestoreSettings = entry.value;

          final localKey = '$_namespace/gacha/$gachaType';
          final localDataString = prefs.getString(localKey);

          Map<String, dynamic> mergedSettings;

          if (localDataString != null) {
            final localSettings =
                json.decode(localDataString) as Map<String, dynamic>;

            // タイムスタンプを比較して新しい方を優先
            final firestoreTime = firestoreSettings['lastUpdated'] as String?;
            final localTime = localSettings['lastUpdated'] as String?;

            if (firestoreTime != null && localTime != null) {
              try {
                final firestoreDateTime = DateTime.parse(firestoreTime);
                final localDateTime = DateTime.parse(localTime);

                if (firestoreDateTime.isAfter(localDateTime)) {
                  mergedSettings = firestoreSettings;
                } else {
                  mergedSettings = localSettings;
                }
              } catch (e) {
                // パースエラー時はパースに成功した方を採用
                DateTime? firestoreDateTime;
                DateTime? localDateTime;

                try {
                  firestoreDateTime = DateTime.parse(firestoreTime);
                } catch (e) {
                  // Firestoreのパース失敗
                }

                try {
                  localDateTime = DateTime.parse(localTime);
                } catch (e) {
                  // ローカルのパース失敗
                }

                if (firestoreDateTime != null && localDateTime != null) {
                  // 両方成功した場合は比較（通常はここには来ない）
                  mergedSettings = firestoreDateTime.isAfter(localDateTime)
                      ? firestoreSettings
                      : localSettings;
                } else if (firestoreDateTime != null) {
                  // Firestoreのみ成功
                  mergedSettings = firestoreSettings;
                } else if (localDateTime != null) {
                  // ローカルのみ成功
                  mergedSettings = localSettings;
                } else {
                  // 両方失敗した場合はFirestoreを優先（新しい物を採用の方針）
                  mergedSettings = firestoreSettings;
                }
              }
            } else if (firestoreTime != null) {
              mergedSettings = firestoreSettings;
            } else {
              mergedSettings = localSettings;
            }
          } else {
            mergedSettings = firestoreSettings;
          }

          // マージした設定をローカルに保存
          await prefs.setString(localKey, json.encode(mergedSettings));
        }
      }

      // ユーザー設定を同期
      final userSettings =
          allSettings['user_settings'] as Map<String, dynamic>?;
      if (userSettings != null) {
        final localKey = '$_namespace/user_settings';
        final localDataString = prefs.getString(localKey);

        Map<String, dynamic> mergedSettings;

        if (localDataString != null) {
          final localSettings =
              json.decode(localDataString) as Map<String, dynamic>;

          // タイムスタンプを比較して新しい方を優先
          final firestoreTime = userSettings['lastUpdated'] as String?;
          final localTime = localSettings['lastUpdated'] as String?;

          if (firestoreTime != null && localTime != null) {
            try {
              final firestoreDateTime = DateTime.parse(firestoreTime);
              final localDateTime = DateTime.parse(localTime);

              if (firestoreDateTime.isAfter(localDateTime)) {
                mergedSettings = userSettings;
              } else {
                mergedSettings = localSettings;
              }
            } catch (e) {
              // パースエラー時はパースに成功した方を採用
              DateTime? firestoreDateTime;
              DateTime? localDateTime;

              try {
                firestoreDateTime = DateTime.parse(firestoreTime);
              } catch (e) {
                // Firestoreのパース失敗
              }

              try {
                localDateTime = DateTime.parse(localTime);
              } catch (e) {
                // ローカルのパース失敗
              }

              if (firestoreDateTime != null && localDateTime != null) {
                // 両方成功した場合は比較（通常はここには来ない）
                mergedSettings = firestoreDateTime.isAfter(localDateTime)
                    ? userSettings
                    : localSettings;
              } else if (firestoreDateTime != null) {
                // Firestoreのみ成功
                mergedSettings = userSettings;
              } else if (localDateTime != null) {
                // ローカルのみ成功
                mergedSettings = localSettings;
              } else {
                // 両方失敗した場合はFirestoreを優先（新しい物を採用の方針）
                mergedSettings = userSettings;
              }
            }
          } else if (firestoreTime != null) {
            mergedSettings = userSettings;
          } else {
            mergedSettings = localSettings;
          }
        } else {
          mergedSettings = userSettings;
        }

        // マージした設定をローカルに保存
        await prefs.setString(localKey, json.encode(mergedSettings));
      }

      // 注意: Pro購入情報はFirebaseから取得しない（RevenueCatで管理）
      // 有料オプション購入状態の同期は削除

      // その他の設定を同期
      final otherSettings =
          allSettings['other_settings'] as Map<String, dynamic>?;
      if (otherSettings != null) {
        for (final entry in otherSettings.entries) {
          final key = entry.key;
          final value = entry.value;

          // 既存のローカル値を確認（タイムスタンプ比較は簡略化）
          if (value != null) {
            if (value is int) {
              await prefs.setInt(key, value);
            } else if (value is String) {
              await prefs.setString(key, value);
            } else if (value is bool) {
              await prefs.setBool(key, value);
            } else if (value is double) {
              await prefs.setDouble(key, value);
            }
          }
        }
      }

      AppLogger.success('Firestoreからの設定同期が完了しました');
    } catch (e) {
      print('Error syncing settings from Firestore for user: $userId - $e');
      // エラー時も処理を継続
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
        print('Starting local settings sync to Firestore for user: $userId');

        final prefs = await SharedPreferences.getInstance();
        final allKeys = prefs.getKeys();

        // ガチャ設定を同期
        final gachaKeys = allKeys
            .where(
              (key) =>
                  key.startsWith('$_namespace/gacha/') &&
                  key != '$_namespace/gacha',
            )
            .toList();

        // パーミッションエラーを検出するためのフラグ
        bool hasPermissionError = false;

        for (final key in gachaKeys) {
          final dataString = prefs.getString(key);
          if (dataString == null) continue;

          try {
            final data = json.decode(dataString) as Map<String, dynamic>;
            final gachaType = key.replaceFirst('$_namespace/gacha/', '');

            // パーミッションエラーが既に発生している場合はスキップ
            if (hasPermissionError) {
              continue;
            }

            // ローカルデータを直接Firestoreに書き込む（読み取りをスキップして高速化）
            final success = await FirestoreSettingsService.saveGachaSettings(
              userId: userId,
              gachaType: gachaType,
              settings: data,
            );

            if (success) {
              print('Synced gacha settings for $gachaType to Firestore');
            } else {
              // 失敗した場合はパーミッションエラーの可能性があるが、次の項目も試す
              print('Warning: Failed to sync gacha settings for $gachaType');
            }
          } catch (e) {
            final errorStr = e.toString().toLowerCase();
            if (errorStr.contains('permission')) {
              hasPermissionError = true;
              print(
                'Permission error detected, skipping remaining Firestore operations',
              );
              break;
            }
            print('Error syncing gacha settings $key to Firestore: $e');
            // 個別のエラーは無視して続行
          }
        }

        // ユーザー設定を同期（パーミッションエラーが発生していない場合のみ）
        if (!hasPermissionError) {
          final userSettingsKey = '$_namespace/user_settings';
          final userSettingsString = prefs.getString(userSettingsKey);
          if (userSettingsString != null) {
            try {
              final userSettings =
                  json.decode(userSettingsString) as Map<String, dynamic>;

              final success = await FirestoreSettingsService.saveUserSettings(
                userId: userId,
                settings: userSettings,
              );

              if (success) {
                print('Synced user settings to Firestore');
              } else {
                print('Warning: Failed to sync user settings to Firestore');
              }
            } catch (e) {
              final errorStr = e.toString().toLowerCase();
              if (errorStr.contains('permission')) {
                hasPermissionError = true;
                print(
                  'Permission error detected, skipping remaining Firestore operations',
                );
              } else {
                print('Error syncing user settings to Firestore: $e');
              }
            }
          }
        }

        // 注意: Pro購入情報はFirebaseにバックアップしない（RevenueCatで管理）
        // 有料オプション購入状態の同期は削除

        // その他の設定を同期（パーミッションエラーが発生していない場合のみ）
        // 注意: 集計設定（aggregation_mode）はガチャ設定の中に含まれるため、個別の同期は不要
        if (!hasPermissionError) {
          final otherSettingKeys = [
            'integral_gacha_exclusion_mode',
            'limit_gacha_exclusion_mode',
            'sequence_gacha_exclusion_mode',
            'unit_gacha_exclusion_mode',
            // 集計設定はガチャ設定の中に含まれるため削除:
            // 'integral_gacha_aggregation_mode',
            // 'limit_gacha_aggregation_mode',
            // 'sequence_gacha_aggregation_mode',
            // 'unit_gacha_aggregation_mode',
            'integral_gacha_max_selections',
            'limit_gacha_max_selections',
            'sequence_gacha_max_selections',
            'unit_gacha_max_selections',
            'unit_gacha_selected_categories',
            _selectedFreeGachasKey, // 選択された無料ガチャのリスト
          ];

          // デバッグ用: 選択された無料ガチャのキーが含まれていることを確認
          print(
            'Syncing other settings, including selected free gachas key: $_selectedFreeGachasKey',
          );

          // ガチャタイプでない問題一覧ページの集計設定キー（*_aggregation_mode_v1）を動的に検出
          // ガチャタイプの集計設定はガチャ設定として既に同期されている
          final aggregationModeKeys = allKeys
              .where(
                (key) =>
                    key.endsWith('_aggregation_mode_v1') &&
                    ![
                      'unit',
                      'integral',
                      'limit',
                      'sequence',
                      'congruence',
                    ].any(
                      (type) => key.startsWith('${type}_aggregation_mode_v1'),
                    ),
              )
              .toList();

          // すべての設定キーを結合
          final allOtherSettingKeys = [
            ...otherSettingKeys,
            ...aggregationModeKeys,
          ];

          for (final settingKey in allOtherSettingKeys) {
            final value = prefs.get(settingKey);
            if (value != null) {
              try {
                // _selectedFreeGachasKeyの場合はJSON文字列をリストに変換
                dynamic settingValue = value;
                if (settingKey == _selectedFreeGachasKey && value is String) {
                  try {
                    final decoded = json.decode(value) as List;
                    settingValue = decoded;
                    print(
                      'Syncing selected free gachas to Firestore: $decoded',
                    );
                  } catch (e) {
                    print('Error decoding selected free gachas: $e');
                    continue; // デコードに失敗した場合はスキップ
                  }
                }

                final success = await FirestoreSettingsService.saveOtherSetting(
                  userId: userId,
                  key: settingKey,
                  value: settingValue,
                );

                if (success) {
                  if (settingKey == _selectedFreeGachasKey) {
                    print(
                      'Successfully synced selected free gachas to Firestore: $settingValue',
                    );
                  } else {
                    print('Synced other setting $settingKey to Firestore');
                  }
                } else {
                  if (settingKey == _selectedFreeGachasKey) {
                    print(
                      'Warning: Failed to sync selected free gachas to Firestore',
                    );
                  } else {
                    print(
                      'Warning: Failed to sync other setting $settingKey to Firestore',
                    );
                  }
                  // パーミッションエラーの可能性があるが、次の項目も試す
                }
              } catch (e) {
                final errorStr = e.toString().toLowerCase();
                if (errorStr.contains('permission')) {
                  hasPermissionError = true;
                  print(
                    'Permission error detected, skipping remaining Firestore operations',
                  );
                  break;
                }
                if (settingKey == _selectedFreeGachasKey) {
                  print('Error syncing selected free gachas to Firestore: $e');
                } else {
                  print(
                    'Error syncing other setting $settingKey to Firestore: $e',
                  );
                }
              }
            } else {
              // 値がnullの場合のログ（デバッグ用）
              if (settingKey == _selectedFreeGachasKey) {
                print(
                  'Warning: Selected free gachas key exists but value is null',
                );
              }
            }
          }
        }

        print('Local settings sync to Firestore completed');
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
        print('Starting reconciled data sync to Firestore for user: $userId');
        await _syncFromFirestore(pushMergedToFirestore: true);
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
      final prefs = await SharedPreferences.getInstance();
      final existingData = await _getLearningData(problem);
      final statusKey = status is LearningStatus
          ? status.key
          : status is ProblemStatus
          ? status.name
          : 'none';

      final history = _normalizeHistoryList(
        existingData['history'],
        maxEntries: learningHistoryRetentionCount,
      );
      if (statusKey != 'none') {
        history.add({
          'status': statusKey,
          'time': DateTime.now().toIso8601String(),
          if (byCalculator) 'byCalculator': true,
        });
      }

      final nextData = _mergeLearningRecordData(
        problemId: problem.id,
        localData: existingData,
        remoteData: {
          'problemId': problem.id,
          'history': history,
          'latestStatus': statusKey,
          'lastUpdated': DateTime.now().toIso8601String(),
        },
      );

      await _saveLearningRecordById(prefs, problem.id, nextData);

      // 認証済みユーザーの場合、Firestoreにも同時に保存
      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.userId;
        if (userId != null) {
          try {
            await _reconcileLearningRecordForProblem(
              prefs: prefs,
              userId: userId,
              problemId: problem.id,
              localData: nextData,
              pushMergedToFirestore: true,
              preferRemoteMetadata: _isCloudAuthoritativeRead,
            );
            print(
              'Successfully reconciled learning record for problem ${problem.id}',
            );
          } catch (e, stackTrace) {
            print('Error saving to Firestore (continuing with local save): $e');
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
      print('Error saving learning record: $e');
      return false;
    }
  }

  /// 学習記録を取得
  /// ローカルデータを優先して即座に返し、バックグラウンドでFirestoreと同期
  static Future<LearningStatus> getLearningRecord(MathProblem problem) async {
    try {
      final localData = await _getLearningData(problem);

      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.userId;
        if (userId != null) {
          final prefs = await SharedPreferences.getInstance();
          if (_isCloudAuthoritativeRead) {
            final merged = await _reconcileLearningRecordForProblem(
              prefs: prefs,
              userId: userId,
              problemId: problem.id,
              localData: localData,
              pushMergedToFirestore: false,
              preferRemoteMetadata: true,
            );
            final statusKey = merged?['latestStatus'] as String?;
            return statusKey != null
                ? LearningStatusExtension.fromKey(statusKey)
                : LearningStatus.none;
          }

          unawaited(() async {
            try {
              await _reconcileLearningRecordForProblem(
                prefs: prefs,
                userId: userId,
                problemId: problem.id,
                localData: localData,
                pushMergedToFirestore: false,
                preferRemoteMetadata: false,
              );
            } catch (e) {
              print('Background sync error (ignored): $e');
            }
          }());
        }
      }

      final statusKey = localData['latestStatus'] as String?;
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
      final cached = _learningHistoryCache[problem.id];
      if (cached != null) return cached;

      final localData = await _getLearningData(problem);
      final history = _normalizeHistoryList(
        localData['history'],
        maxEntries: learningHistoryRetentionCount,
      );

      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.userId;
        if (userId != null) {
          final prefs = await SharedPreferences.getInstance();
          if (_isCloudAuthoritativeRead) {
            final merged = await _reconcileLearningRecordForProblem(
              prefs: prefs,
              userId: userId,
              problemId: problem.id,
              localData: localData,
              pushMergedToFirestore: false,
              preferRemoteMetadata: true,
            );
            final mergedHistory = _normalizeHistoryList(
              merged?['history'],
              maxEntries: learningHistoryRetentionCount,
            );
            _learningHistoryCache[problem.id] = mergedHistory;
            return mergedHistory;
          }

          unawaited(() async {
            try {
              await _reconcileLearningRecordForProblem(
                prefs: prefs,
                userId: userId,
                problemId: problem.id,
                localData: localData,
                pushMergedToFirestore: false,
                preferRemoteMetadata: false,
              );
            } catch (e) {
              print('Background sync error (ignored): $e');
            }
          }());
        }
      }

      final migratedHistory = history.map((h) {
        final status = h['status'] as String?;
        final time = h['time'] as String?;
        final byCalc = h['byCalculator'];

        // 古い形式（LearningStatus.key）を新しい形式（ProblemStatus.name）に変換
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
        return out;
      }).toList();

      _learningHistoryCache[problem.id] = migratedHistory;
      return migratedHistory;
    } catch (e) {
      print('Error getting learning history: $e');
      // エラー時は空のリストを返す（問題は除外されない）
      return [];
    }
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

    final prefs = await SharedPreferences.getInstance();
    final out = <String, List<Map<String, dynamic>>>{};

    for (final id in ids) {
      final cached = _learningHistoryCache[id];
      if (cached != null) {
        out[id] = cached;
        continue;
      }

      final key = '$_namespace/learning/$id';
      final dataString = prefs.getString(key);
      if (dataString == null) {
        _learningHistoryCache[id] = const [];
        out[id] = const [];
        continue;
      }

      try {
        final decoded = json.decode(dataString);
        if (decoded is Map<String, dynamic>) {
          final historyAny = decoded['history'];
          final history = <Map<String, dynamic>>[];
          if (historyAny is List) {
            for (final h in historyAny) {
              if (h is Map) {
                final status = h['status'];
                final time = h['time'];
                final byCalc = h['byCalculator'];
                history.add({
                  'status': status is String ? status : 'none',
                  'time': time is String ? time : null,
                  if (byCalc is bool) 'byCalculator': byCalc,
                });
              }
            }
          }

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
            if (byCalc is bool) out['byCalculator'] = byCalc;
            return out;
          }).toList();

          _learningHistoryCache[id] = migratedHistory;
          out[id] = migratedHistory;
        } else {
          _learningHistoryCache[id] = const [];
          out[id] = const [];
        }
      } catch (_) {
        _learningHistoryCache[id] = const [];
        out[id] = const [];
      }
    }

    return out;
  }

  /// 学習記録の履歴を保存
  static Future<bool> saveLearningHistory(
    dynamic problem,
    List<Map<String, dynamic>> history,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = await _getLearningData(problem);
      final normalizedHistory = _normalizeHistoryList(
        history,
        maxEntries: learningHistoryRetentionCount,
      );
      final nextData = _mergeLearningRecordData(
        problemId: problem.id,
        localData: existingData,
        remoteData: {
          'problemId': problem.id,
          'history': normalizedHistory,
          'latestStatus': _deriveLatestStatus(normalizedHistory),
          'lastUpdated': DateTime.now().toIso8601String(),
        },
      );

      await _saveLearningRecordById(prefs, problem.id, nextData);

      // 認証済みユーザーの場合、Firestoreにも同時に保存
      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.userId;
        if (userId != null) {
          try {
            await _reconcileLearningRecordForProblem(
              prefs: prefs,
              userId: userId,
              problemId: problem.id,
              localData: nextData,
              pushMergedToFirestore: true,
              preferRemoteMetadata: _isCloudAuthoritativeRead,
            );
            print(
              'Successfully saved learning history to Firestore for problem ${problem.id}',
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
      final success = await saveLearningHistory(problem, const []);

      if (success) {
        print(
          'Successfully cleared learning history (set all slots to none) for problem ${problem.id}',
        );
      } else {
        print(
          'Warning: Failed to clear learning history for problem ${problem.id}',
        );
      }

      return success;
    } catch (e) {
      print('Error clearing learning history: $e');
      return false;
    }
  }

  /// 学習データを取得（内部メソッド）
  static Future<Map<String, dynamic>> _getLearningData(dynamic problem) async {
    try {
      final cached = _learningDataCache[problem.id];
      if (cached != null) return Map<String, dynamic>.from(cached);

      final prefs = await SharedPreferences.getInstance();
      final key = '$_namespace/learning/${problem.id}';
      final dataString = prefs.getString(key);

      if (dataString != null) {
        final decoded = json.decode(dataString);
        if (decoded is Map<String, dynamic>) {
          final m = Map<String, dynamic>.from(decoded);
          m['history'] = _normalizeHistoryList(
            m['history'],
            maxEntries: learningHistoryRetentionCount,
          );
          m['latestStatus'] = _deriveLatestStatus(
            m['history'] as List<Map<String, dynamic>>,
          );
          m['lastUpdated'] = _deriveMergedLastUpdated(
            history: m['history'] as List<Map<String, dynamic>>,
            localData: m,
            remoteData: null,
          );
          _learningDataCache[problem.id] = m;
          return Map<String, dynamic>.from(m);
        }
      }

      // デフォルトデータ
      final d = {
        'problemId': problem.id,
        'latestStatus': 'none',
        'history': <Map<String, dynamic>>[],
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      _learningDataCache[problem.id] = d;
      return Map<String, dynamic>.from(d);
    } catch (e) {
      print('Error getting learning data: $e');
      final d = {
        'problemId': problem.id,
        'latestStatus': 'none',
        'history': <Map<String, dynamic>>[],
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      _learningDataCache[problem.id] = d;
      return Map<String, dynamic>.from(d);
    }
  }

  // ============================================================================
  // ガチャ管理（シンプル版）
  // ============================================================================

  /// ガチャ設定を保存
  /// 注意: ログイン前の場合はローカルのみに保存される
  /// ログイン後は syncLocalSettingsToFirestore() で同期される
  static Future<bool> saveGachaSettings(
    String gachaType,
    Map<String, dynamic> settings,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_namespace/gacha/$gachaType';

      // デフォルト設定とマージ
      final defaultSettings = _getDefaultGachaSettings();
      defaultSettings.addAll(settings);
      defaultSettings['updatedAt'] = DateTime.now().toIso8601String();
      defaultSettings['lastUpdated'] = DateTime.now().toIso8601String();

      // ローカルに即座に保存（UXを下げない）
      await prefs.setString(key, json.encode(defaultSettings));

      // 認証済みユーザーの場合、Firestoreにも同時に保存（非同期、エラーは無視）
      // 注意: ログイン前の場合はこの処理は実行されない
      // ログイン後は syncLocalSettingsToFirestore() で同期される
      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.userId;
        if (userId != null) {
          FirestoreSettingsService.saveGachaSettings(
                userId: userId,
                gachaType: gachaType,
                settings: defaultSettings,
              )
              .then((success) {
                if (success) {
                  print(
                    'Successfully saved gacha settings to Firestore for $gachaType',
                  );
                } else {
                  print(
                    'Warning: Failed to save gacha settings to Firestore for $gachaType',
                  );
                }
              })
              .catchError((e) {
                print(
                  'Error saving gacha settings to Firestore (continuing with local save): $e',
                );
                // Firestoreエラー時はローカルのみで動作継続
              });
        }
      }

      return true;
    } catch (e) {
      print('Error saving gacha settings: $e');
      return false;
    }
  }

  /// ガチャ設定を取得
  /// ローカルデータを優先して即座に返し、バックグラウンドでFirestoreと同期
  static Future<Map<String, dynamic>> getGachaSettings(String gachaType) async {
    try {
      // まずローカルデータを即座に取得（遅延なし）
      final prefs = await SharedPreferences.getInstance();
      final key = '$_namespace/gacha/$gachaType';
      final settingsString = prefs.getString(key);

      Map<String, dynamic> localSettings;
      if (settingsString != null) {
        final decoded = json.decode(settingsString);
        if (decoded is Map<String, dynamic>) {
          localSettings = decoded;
        } else {
          localSettings = _getDefaultGachaSettings();
        }
      } else {
        localSettings = _getDefaultGachaSettings();
      }

      // バックグラウンドでFirestoreから取得を試みる（非同期、エラーは無視）
      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.userId;
        if (userId != null) {
          // 非同期でFirestoreから取得（エラーは無視、UIをブロックしない）
          FirestoreSettingsService.getGachaSettings(
                userId: userId,
                gachaType: gachaType,
              )
              .timeout(const Duration(seconds: 2), onTimeout: () => null)
              .then((firestoreSettings) async {
                if (firestoreSettings != null) {
                  // タイムスタンプを比較して新しい方を優先
                  final localTime = localSettings['lastUpdated'] as String?;
                  final firestoreTime =
                      firestoreSettings['lastUpdated'] as String?;

                  if (localTime != null && firestoreTime != null) {
                    try {
                      final localDateTime = DateTime.parse(localTime);
                      final firestoreDateTime = DateTime.parse(firestoreTime);

                      if (firestoreDateTime.isAfter(localDateTime)) {
                        // Firestoreのデータが新しい場合は、ローカルデータを更新
                        await prefs.setString(
                          key,
                          json.encode(firestoreSettings),
                        );
                        print(
                          'Background sync: Updated local gacha settings from Firestore for $gachaType',
                        );
                      } else {
                        // ローカルデータが新しい場合は、Firestoreを更新
                        await FirestoreSettingsService.saveGachaSettings(
                          userId: userId,
                          gachaType: gachaType,
                          settings: localSettings,
                        );
                      }
                    } catch (e) {
                      // パースエラー時はパースに成功した方を採用
                      DateTime? localDateTime;
                      DateTime? firestoreDateTime;

                      try {
                        localDateTime = DateTime.parse(localTime);
                      } catch (e) {
                        // ローカルのパース失敗
                      }

                      try {
                        firestoreDateTime = DateTime.parse(firestoreTime);
                      } catch (e) {
                        // Firestoreのパース失敗
                      }

                      if (firestoreDateTime != null && localDateTime != null) {
                        // 両方成功した場合は比較（通常はここには来ない）
                        if (firestoreDateTime.isAfter(localDateTime)) {
                          await prefs.setString(
                            key,
                            json.encode(firestoreSettings),
                          );
                          print(
                            'Background sync: Updated local gacha settings from Firestore for $gachaType',
                          );
                        } else {
                          await FirestoreSettingsService.saveGachaSettings(
                            userId: userId,
                            gachaType: gachaType,
                            settings: localSettings,
                          );
                        }
                      } else if (firestoreDateTime != null) {
                        // Firestoreのみ成功
                        await prefs.setString(
                          key,
                          json.encode(firestoreSettings),
                        );
                        print(
                          'Background sync: Updated local gacha settings from Firestore for $gachaType',
                        );
                      } else if (localDateTime != null) {
                        // ローカルのみ成功
                        await FirestoreSettingsService.saveGachaSettings(
                          userId: userId,
                          gachaType: gachaType,
                          settings: localSettings,
                        );
                      } else {
                        // 両方失敗した場合はFirestoreを優先（新しい物を採用の方針）
                        await prefs.setString(
                          key,
                          json.encode(firestoreSettings),
                        );
                        print(
                          'Background sync: Updated local gacha settings from Firestore for $gachaType',
                        );
                      }
                    }
                  } else if (firestoreTime != null) {
                    // ローカルにタイムスタンプがない場合は、Firestoreのデータを使用
                    await prefs.setString(key, json.encode(firestoreSettings));
                    print(
                      'Background sync: Updated local gacha settings from Firestore for $gachaType',
                    );
                  }
                }
              })
              .catchError((e) {
                // エラーは無視（バックグラウンド処理のため）
                print('Background sync error (ignored): $e');
              });
        }
      }

      // ローカルデータを即座に返す
      return localSettings;
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
      final key = '$_namespace/user_settings';

      // タイムスタンプを追加
      final settingsWithTimestamp = Map<String, dynamic>.from(settings);
      settingsWithTimestamp['lastUpdated'] = DateTime.now().toIso8601String();

      // ローカルに即座に保存（UXを下げない）
      await prefs.setString(key, json.encode(settingsWithTimestamp));

      // 認証済みユーザーの場合、Firestoreにも同時に保存（非同期、エラーは無視）
      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.userId;
        if (userId != null) {
          FirestoreSettingsService.saveUserSettings(
                userId: userId,
                settings: settingsWithTimestamp,
              )
              .then((success) {
                if (success) {
                  print('Successfully saved user settings to Firestore');
                } else {
                  print('Warning: Failed to save user settings to Firestore');
                }
              })
              .catchError((e) {
                print(
                  'Error saving user settings to Firestore (continuing with local save): $e',
                );
                // Firestoreエラー時はローカルのみで動作継続
              });
        }
      }

      return true;
    } catch (e) {
      print('Error saving user settings: $e');
      return false;
    }
  }

  /// ユーザー設定を取得（将来の拡張用）
  /// ローカルデータを優先して即座に返し、バックグラウンドでFirestoreと同期
  static Future<Map<String, dynamic>> getUserSettings() async {
    try {
      // まずローカルデータを即座に取得（遅延なし）
      final prefs = await SharedPreferences.getInstance();
      final key = '$_namespace/user_settings';
      final settingsString = prefs.getString(key);

      Map<String, dynamic> localSettings;
      if (settingsString != null) {
        final decoded = json.decode(settingsString);
        if (decoded is Map<String, dynamic>) {
          localSettings = decoded;
        } else {
          localSettings = {};
        }
      } else {
        localSettings = {};
      }

      // バックグラウンドでFirestoreから取得を試みる（非同期、エラーは無視）
      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.userId;
        if (userId != null) {
          // 非同期でFirestoreから取得（エラーは無視、UIをブロックしない）
          FirestoreSettingsService.getUserSettings(userId: userId)
              .timeout(const Duration(seconds: 2), onTimeout: () => null)
              .then((firestoreSettings) async {
                if (firestoreSettings != null) {
                  // タイムスタンプを比較して新しい方を優先
                  final localTime = localSettings['lastUpdated'] as String?;
                  final firestoreTime =
                      firestoreSettings['lastUpdated'] as String?;

                  if (localTime != null && firestoreTime != null) {
                    try {
                      final localDateTime = DateTime.parse(localTime);
                      final firestoreDateTime = DateTime.parse(firestoreTime);

                      if (firestoreDateTime.isAfter(localDateTime)) {
                        // Firestoreのデータが新しい場合は、ローカルデータを更新
                        await prefs.setString(
                          key,
                          json.encode(firestoreSettings),
                        );
                        print(
                          'Background sync: Updated local user settings from Firestore',
                        );
                      } else {
                        // ローカルデータが新しい場合は、Firestoreを更新
                        await FirestoreSettingsService.saveUserSettings(
                          userId: userId,
                          settings: localSettings,
                        );
                      }
                    } catch (e) {
                      // パースエラー時はパースに成功した方を採用
                      DateTime? localDateTime;
                      DateTime? firestoreDateTime;

                      try {
                        localDateTime = DateTime.parse(localTime);
                      } catch (e) {
                        // ローカルのパース失敗
                      }

                      try {
                        firestoreDateTime = DateTime.parse(firestoreTime);
                      } catch (e) {
                        // Firestoreのパース失敗
                      }

                      if (firestoreDateTime != null && localDateTime != null) {
                        // 両方成功した場合は比較（通常はここには来ない）
                        if (firestoreDateTime.isAfter(localDateTime)) {
                          await prefs.setString(
                            key,
                            json.encode(firestoreSettings),
                          );
                          print(
                            'Background sync: Updated local user settings from Firestore',
                          );
                        } else {
                          await FirestoreSettingsService.saveUserSettings(
                            userId: userId,
                            settings: localSettings,
                          );
                        }
                      } else if (firestoreDateTime != null) {
                        // Firestoreのみ成功
                        await prefs.setString(
                          key,
                          json.encode(firestoreSettings),
                        );
                        print(
                          'Background sync: Updated local user settings from Firestore',
                        );
                      } else if (localDateTime != null) {
                        // ローカルのみ成功
                        await FirestoreSettingsService.saveUserSettings(
                          userId: userId,
                          settings: localSettings,
                        );
                      } else {
                        // 両方失敗した場合はFirestoreを優先（新しい物を採用の方針）
                        await prefs.setString(
                          key,
                          json.encode(firestoreSettings),
                        );
                        print(
                          'Background sync: Updated local user settings from Firestore',
                        );
                      }
                    }
                  } else if (firestoreTime != null) {
                    // ローカルにタイムスタンプがない場合は、Firestoreのデータを使用
                    await prefs.setString(key, json.encode(firestoreSettings));
                    print(
                      'Background sync: Updated local user settings from Firestore',
                    );
                  }
                }
              })
              .catchError((e) {
                // エラーは無視（バックグラウンド処理のため）
                print('Background sync error (ignored): $e');
              });
        }
      }

      // ローカルデータを即座に返す
      return localSettings;
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

      print('Cleared $clearedCount account-specific data keys');
      return true;
    } catch (e) {
      print('Error clearing account-specific data: $e');
      return false;
    }
  }

  /// アカウント切り替え時のデータ同期処理
  /// 前のアカウントのローカルデータをクリアし、新しいアカウントのFirestoreデータを取得
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

        // アカウント切り替え時はクラウドを正とし、旧ローカルはアップロードしない
        await _syncFromFirestore(pushMergedToFirestore: false);
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

  /// 選択された無料ガチャのリストを取得
  static Future<List<String>> getSelectedFreeGachas() async {
    try {
      // まずローカルデータを即座に取得（遅延なし）
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_selectedFreeGachasKey);

      List<String> localSelected = [];
      if (jsonString != null) {
        try {
          final List<dynamic> decoded = json.decode(jsonString);
          localSelected = decoded.cast<String>();
        } catch (e) {
          print('Error decoding selected free gachas: $e');
        }
      }

      // バックグラウンドでFirestoreから取得を試みる（非同期、エラーは無視）
      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.userId;
        if (userId != null) {
          FirestoreSettingsService.getOtherSetting(
                userId: userId,
                key: _selectedFreeGachasKey,
              )
              .timeout(const Duration(seconds: 2), onTimeout: () => null)
              .then((firestoreValue) async {
                if (firestoreValue != null && firestoreValue is List) {
                  final firestoreSelected = firestoreValue.cast<String>();
                  if (firestoreSelected.isNotEmpty) {
                    final jsonString = json.encode(firestoreSelected);
                    await prefs.setString(_selectedFreeGachasKey, jsonString);
                    print(
                      'Background sync: Updated selected free gachas from Firestore',
                    );
                  }
                }
              })
              .catchError((e) {
                print('Background sync error (ignored): $e');
              });
        }
      }

      return localSelected;
    } catch (e) {
      print('Error getting selected free gachas: $e');
      return [];
    }
  }

  /// 選択された無料ガチャを保存
  /// 注意: 2ガチャ選択時は通常ログイン前なので、ローカルのみに保存される
  /// ログイン後は syncLocalSettingsToFirestore() で同期される
  static Future<bool> saveSelectedFreeGachas(List<String> prefsPrefixes) async {
    try {
      if (prefsPrefixes.length > 2) {
        print(
          'Warning: More than 2 gachas selected. Only first 2 will be saved.',
        );
        prefsPrefixes = prefsPrefixes.take(2).toList();
      }

      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(prefsPrefixes);
      await prefs.setString(_selectedFreeGachasKey, jsonString);

      // 認証済みユーザーの場合、Firestoreにもバックアップ（非同期、エラーは無視）
      // 注意: 2ガチャ選択時は通常ログイン前なので、この処理は実行されない
      // ログイン後は syncLocalSettingsToFirestore() で同期される
      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.userId;
        if (userId != null) {
          FirestoreSettingsService.saveOtherSetting(
                userId: userId,
                key: _selectedFreeGachasKey,
                value: prefsPrefixes,
              )
              .then((success) {
                if (success) {
                  print('Successfully saved selected free gachas to Firestore');
                } else {
                  print(
                    'Warning: Failed to save selected free gachas to Firestore',
                  );
                }
              })
              .catchError((e) {
                print(
                  'Error saving selected free gachas to Firestore (continuing with local save): $e',
                );
              });
        }
      }

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
