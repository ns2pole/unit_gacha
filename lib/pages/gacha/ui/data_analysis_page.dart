// lib/pages/gacha/ui/data_analysis_page.dart
// データ分析ページ

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:intl/intl.dart';
import '../../../localization/app_localizations.dart';
import '../../../localization/app_locale.dart';
import '../../../problems/unit/symbol.dart' show UnitCategory;
import '../../../services/auth/firebase_auth_service.dart';
import '../../../services/auth/firestore_attempt_event_service.dart' show AttemptEventUpsertErrorKind;
import '../../../services/auth/firestore_public_profile_service.dart';
import '../../../services/ranking/unit_gacha_leaderboard_service.dart';
import '../../../services/problems/simple_data_manager.dart';
import '../pages/gacha_settings_page.dart' show GachaFilterMode;
import '../logic/completion_rate_calculator.dart' show CompletionRateCalculator, CompletionRateResult;
import '../logic/weekly_problem_statistics.dart' show WeeklyProblemStatistics, WeeklyExerciseRecord;
import '../formatting/unit_formatters.dart' show formatExpression, formatUnitString;
import 'widgets/weekly_problem_chart.dart';
import 'widgets/completion_rate_bar_chart.dart';
import 'widgets/weekly_category_pie_chart.dart';
import 'widgets/weekly_accuracy_chart.dart';
import 'utils/category_color_helper.dart' show getCategoryColor;
import '../../../managers/timer_manager.dart';
import 'unit_gacha_common_header.dart';
import '../../../widgets/home/background_image_widget.dart';
import '../../../widgets/ranking/unit_gacha_ranking_settings_panel.dart';

/// データ分析ページ
class DataAnalysisPage extends StatefulWidget {
  final Set<UnitCategory> selectedCategories;
  final GachaFilterMode gachaFilterMode;
  final VoidCallback onClose;
  final TimerManager? timerManager;
  final bool isHelpPageVisible;
  final bool isProblemListVisible;
  final bool isReferenceTableVisible;
  final bool isScratchPaperMode;
  final bool showFilterSettings;
  final VoidCallback? onHelpToggle;
  final VoidCallback? onProblemListToggle;
  final VoidCallback? onReferenceTableToggle;
  final VoidCallback? onScratchPaperToggle;
  final VoidCallback? onFilterToggle;
  final VoidCallback? onLoginTap;
  final VoidCallback? onDataAnalysisNavigate;
  final bool isDataAnalysisActive;

  const DataAnalysisPage({
    super.key,
    required this.selectedCategories,
    required this.gachaFilterMode,
    required this.onClose,
    this.timerManager,
    this.isHelpPageVisible = false,
    this.isProblemListVisible = false,
    this.isReferenceTableVisible = false,
    this.isScratchPaperMode = false,
    this.showFilterSettings = false,
    this.onHelpToggle,
    this.onProblemListToggle,
    this.onReferenceTableToggle,
    this.onScratchPaperToggle,
    this.onFilterToggle,
    this.onLoginTap,
    this.onDataAnalysisNavigate,
    this.isDataAnalysisActive = false,
  });

  @override
  State<DataAnalysisPage> createState() => _DataAnalysisPageState();
}

class _DataAnalysisPageState extends State<DataAnalysisPage> {
  bool _isLoading = true;
  Map<UnitCategory, CompletionRateResult> _results = {};
  int _currentWeekOffset = 0;
  late TimerManager _timerManager;
  Future<UnitGachaLeaderboardSnapshot>? _overallLeaderboardFuture;
  final Map<String, Future<UnitGachaLeaderboardSnapshot>> _weeklyLeaderboardFutureCache = {};
  String? _leaderboardUserIdCache;
  bool _isRankingRefreshing = false;
  int _rankingRefreshOpId = 0;
  UnitGachaAttemptSyncResult? _lastAttemptSync;
  int? _attemptQueueLen;

  VoidCallback? _learningEpochListener;
  Timer? _learningEpochDebounce;

  static const double _titleEpsilon = 0.0001;
  static const double _overallStarEpsilon = 1e-9;

  ({int level, String title}) _getTitleByCompletionRate({
    required BuildContext context,
    required UnitCategory category,
    required double percentageRaw,
  }) {
    final l10n = AppLocalizations.of(context);
    final p = percentageRaw.clamp(0.0, 100.0);
    final isFull = p >= (100.0 - _titleEpsilon);

    switch (category) {
      case UnitCategory.mechanics:
        if (isFull) return (level: 7, title: l10n.titleMechanicsMaster);
        if (p >= 85) return (level: 6, title: l10n.titleMechanicsExpert);
        if (p >= 65) return (level: 5, title: l10n.titleHamiltonianBeliever);
        if (p >= 50) return (level: 4, title: l10n.titleNewtonBeliever);
        if (p >= 30) return (level: 3, title: l10n.titleCelestialObserver);
        if (p >= 10) return (level: 2, title: l10n.titleEquationUser);
        return (level: 1, title: l10n.titleMechanicsApprentice);
      case UnitCategory.thermodynamics:
        if (isFull) return (level: 5, title: l10n.titleThermodynamicsMaster);
        if (p >= 75) return (level: 4, title: l10n.titleThermodynamicsExpert);
        if (p >= 50) return (level: 3, title: l10n.titleEntropyBeliever);
        if (p >= 25) return (level: 2, title: l10n.titleTemperatureFriend);
        return (level: 1, title: l10n.titleThermodynamicsApprentice);
      case UnitCategory.waves:
        // 波動は熱力学と同じ刻み（0-25,25-50,50-75,75-<100,100）
        if (isFull) return (level: 5, title: l10n.titleWavesMaster);
        if (p >= 75) return (level: 4, title: l10n.titleWavesExpert);
        if (p >= 50) return (level: 3, title: l10n.titleFourierBeliever);
        if (p >= 25) return (level: 2, title: l10n.titleSuperpositionMan);
        return (level: 1, title: l10n.titleWavesApprentice);
      case UnitCategory.electromagnetism:
        // 電磁気は力学と同じ刻み
        if (isFull) return (level: 7, title: l10n.titleElectromagnetismMaster);
        if (p >= 85) return (level: 6, title: l10n.titleElectromagnetismExpert);
        if (p >= 65) return (level: 5, title: l10n.titleMaxwellBeliever);
        if (p >= 50) return (level: 4, title: l10n.titleElectromagneticFieldUser);
        if (p >= 30) return (level: 3, title: l10n.titleMagneticFieldUser);
        if (p >= 10) return (level: 2, title: l10n.titleElectricFieldUser);
        return (level: 1, title: l10n.titleElectromagnetismApprentice);
      case UnitCategory.atom:
        // 原子は熱力学と同じ刻み（5段階）
        if (isFull) return (level: 5, title: l10n.titleAtomMaster);
        if (p >= 75) return (level: 4, title: l10n.titleAtomExpert);
        if (p >= 50) return (level: 3, title: l10n.titleBohrBeliever);
        if (p >= 25) return (level: 2, title: l10n.titleQuantumFriend);
        return (level: 1, title: l10n.titleAtomApprentice);
    }
  }

  Widget _buildRoundedSubtitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  // ===========================================================================
  // Ranking UI (unit_gacha)
  // - Reads leaderboard docs from Firestore
  // - Also triggers best-effort background sync of queued attempt events, then refreshes UI
  // ===========================================================================

  bool get _isLoggedIn => FirebaseAuthService.isAuthenticated;
  String? get _userId => FirebaseAuthService.userId;

  String _weekKeyForOffset(int weekOffset) {
    // IMPORTANT:
    // Match Cloud Functions `weekKeyFromServerDate` implementation.
    // Weekly is defined by JST (Mon-Sun) using server commit time.
    //
    // We compute the Monday (00:00) of the current JST week, then apply offset.
    final utcNow = DateTime.now().toUtc();
    final jst = utcNow.add(const Duration(hours: 9));

    // Dart weekday: 1=Mon..7=Sun (equivalent to JS shifted UTCDay with Sunday handled as 6).
    final daysFromMonday = jst.weekday - 1; // Sun(7)->6, Mon(1)->0

    final jstCalendarDayUtc = DateTime.utc(jst.year, jst.month, jst.day);
    final thisWeekMondayUtc = jstCalendarDayUtc.subtract(Duration(days: daysFromMonday));
    final targetMondayUtc = thisWeekMondayUtc.add(Duration(days: weekOffset * 7));

    return DateFormat('yyyy-MM-dd').format(targetMondayUtc);
  }

  String _displayNameFor({required String userId, required String? nickname}) {
    final n = nickname?.trim();
    if (n != null && n.isNotEmpty) return n;
    final short = userId.length >= 6 ? userId.substring(0, 6) : userId;
    return 'Player#$short';
  }

  void _ensureLeaderboardFutures() {
    final uid = _userId;
    // 未ログイン or uid不明の場合はキャッシュをクリア
    if (uid == null) {
      _leaderboardUserIdCache = null;
      _overallLeaderboardFuture = null;
      _weeklyLeaderboardFutureCache.clear();
      return;
    }

    // ユーザーが切り替わったらキャッシュをクリア
    if (_leaderboardUserIdCache != uid) {
      _leaderboardUserIdCache = uid;
      _overallLeaderboardFuture = null;
      _weeklyLeaderboardFutureCache.clear();
    }

    _overallLeaderboardFuture ??= UnitGachaLeaderboardService.fetchOverall(myUserId: uid, topLimit: 10);
    final weekKey = _weekKeyForOffset(_currentWeekOffset);
    _weeklyLeaderboardFutureCache.putIfAbsent(
      weekKey,
      () => UnitGachaLeaderboardService.fetchWeekly(
        weekKey: weekKey,
        myUserId: uid,
        topLimit: 10,
      ),
    );
  }

  void _refreshOverallLeaderboard() {
    final uid = _userId;
    if (uid == null) return;
    _overallLeaderboardFuture = UnitGachaLeaderboardService.fetchOverall(myUserId: uid, topLimit: 10);
  }

  void _refreshWeeklyLeaderboardForOffset(int weekOffset) {
    final uid = _userId;
    if (uid == null) return;
    final weekKey = _weekKeyForOffset(weekOffset);
    _weeklyLeaderboardFutureCache[weekKey] = UnitGachaLeaderboardService.fetchWeekly(
      weekKey: weekKey,
      myUserId: uid,
      topLimit: 10,
    );
  }

  // Ranking settings (participation/nickname) moved to AuthPage.

  void _kickoffRankingBackgroundRefresh({required String reason, bool bestEffortWeeklyRetry = true}) {
    final uid = _userId;
    if (uid == null) return;

    final opId = ++_rankingRefreshOpId;
    if (mounted) {
      setState(() => _isRankingRefreshing = true);
    }

    unawaited(() async {
      // 0) Best-effort: auto-repair legacy participation mismatch
      // (overall leaderboard exists but public_profile.participating is missing/false).
      try {
        await FirestorePublicProfileService.autoRepairUnitGachaParticipationIfNeeded(userId: uid);
      } catch (_) {}

      // 1) Best-effort: upload queued attempt events (non-blocking for the user)
      UnitGachaAttemptSyncResult? attemptSync;
      try {
        attemptSync = await SimpleDataManager.syncUnitGachaAttemptEventsToFirestore();
      } catch (_) {
        // Ignore: we still attempt to refresh reads (could have already been synced)
      }
      int? queueLen;
      try {
        queueLen = await SimpleDataManager.getUnitGachaAttemptQueueLength();
      } catch (_) {}

      if (!mounted) return;
      if (opId != _rankingRefreshOpId) return;
      setState(() {
        _lastAttemptSync = attemptSync ?? _lastAttemptSync;
        _attemptQueueLen = queueLen ?? _attemptQueueLen;
      });

      // 2) Refresh reads (overall + current weekly)
      setState(() {
        _refreshOverallLeaderboard();
        _refreshWeeklyLeaderboardForOffset(_currentWeekOffset);
      });

      // 3) Weekly can lag (Functions / indexing / propagation). Retry a few times, non-blocking.
      if (bestEffortWeeklyRetry) {
        final currentOffset = _currentWeekOffset;
        final weekKey = _weekKeyForOffset(currentOffset);

        const delays = <Duration>[
          Duration(milliseconds: 700),
          Duration(milliseconds: 1100),
          Duration(milliseconds: 1600),
        ];

        for (final d in delays) {
          await Future<void>.delayed(d);
          if (!mounted) return;
          if (opId != _rankingRefreshOpId) return;

          try {
            final snap = await UnitGachaLeaderboardService.fetchWeekly(
              weekKey: weekKey,
              myUserId: uid,
              topLimit: 10,
            );
            // If myScore appears, weekly doc exists → stop retrying.
            if (snap.myScore != null) {
              break;
            }
          } catch (_) {
            // ignore and keep retrying
          }

          if (!mounted) return;
          if (opId != _rankingRefreshOpId) return;
          setState(() {
            _refreshWeeklyLeaderboardForOffset(currentOffset);
          });
        }
      }

      if (!mounted) return;
      if (opId != _rankingRefreshOpId) return;
      setState(() => _isRankingRefreshing = false);
    }());
  }

  void _showRankingSettingsSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 16 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.rankingSettings,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                UnitGachaRankingSettingsPanel(
                  showWhenLoggedOut: true,
                  onRankingChanged: () => _kickoffRankingBackgroundRefresh(
                    reason: 'ranking_settings_changed',
                    bestEffortWeeklyRetry: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankingList({
    required String title,
    required bool showSolvedFailed,
    required Future<UnitGachaLeaderboardSnapshot>? future,
    required String? myNickname,
    String? emptyMessage,
  }) {
    if (!_isLoggedIn) {
      final l10n = AppLocalizations.of(context);
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(230),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: widget.onLoginTap,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.rankingLoginButton,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (future == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final l10n = AppLocalizations.of(context);
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(230),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showRankingSettingsSheet(context),
                      icon: const Icon(Icons.settings),
                      visualDensity: VisualDensity.compact,
                      tooltip: l10n.rankingSettings,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.rankingLoadFailed,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.rankingLoadFailedHint,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final lb = snapshot.data!;
        final uid = _userId!;
        final myName = _displayNameFor(userId: uid, nickname: myNickname);
        final myRank = lb.myRank;
        final total = lb.totalUsers;
        final myScore = lb.myScore;

        final isJa = AppLocale.isJapanese(context);
        final attemptSync = _lastAttemptSync;
        final attemptQueueLen = _attemptQueueLen;
        String attemptSyncLine() {
          final q = attemptQueueLen;
          final parts = <String>[];
          // NOTE: 「送信待ち」「送信残り」は統計ページのランキングでは一旦非表示（必要なら復活）
          // if (q != null) parts.add(isJa ? '送信待ち: $q' : 'Queued: $q');
          if (attemptSync != null) {
            parts.add(isJa ? '送信: ${attemptSync.sent}/${attemptSync.attempted}' : 'Sent: ${attemptSync.sent}/${attemptSync.attempted}');
            // parts.add(isJa ? '残: ${attemptSync.remaining}' : 'Remain: ${attemptSync.remaining}');
            if (attemptSync.lastErrorKind != null) {
              final k = attemptSync.lastErrorKind!;
              final kStr = switch (k) {
                AttemptEventUpsertErrorKind.permissionDenied => isJa ? '権限エラー' : 'permission',
                AttemptEventUpsertErrorKind.unauthenticated => isJa ? '未ログイン' : 'unauth',
                AttemptEventUpsertErrorKind.network => isJa ? '通信' : 'network',
                AttemptEventUpsertErrorKind.unknown => isJa ? '不明' : 'unknown',
              };
              parts.add(isJa ? '直近: $kStr' : 'Last: $kStr');
            }
          }
          if (parts.isEmpty) return isJa ? 'ランキングが更新されない場合は「同期&更新」を押してください' : 'If ranking does not update, tap “Sync & Refresh”.';
          return parts.join(isJa ? ' / ' : ' / ');
        }
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(230),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: _isRankingRefreshing
                        ? null
                        : () => _kickoffRankingBackgroundRefresh(
                              reason: 'manual_sync_refresh',
                              bestEffortWeeklyRetry: true,
                            ),
                    icon: const Icon(Icons.cloud_sync_outlined),
                    iconSize: 26,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    padding: const EdgeInsets.all(6),
                    tooltip: isJa ? '同期' : 'Sync',
                  ),
                  IconButton(
                    onPressed: () => _showRankingSettingsSheet(context),
                    icon: const Icon(Icons.settings),
                    iconSize: 26,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    padding: const EdgeInsets.all(6),
                    tooltip: l10n.rankingSettings,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                attemptSyncLine(),
                style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600),
              ),
              if (_isRankingRefreshing) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isJa ? '更新中…' : 'Updating…',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              if (myRank != null && total != null && myScore != null) ...[
                Text(
                  l10n.yourRanking(myName, myScore, myRank, total),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ] else ...[
                Text(
                  l10n.yourRankingNoRank(myName),
                  style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w600),
                ),
              ],
              if (lb.top.isEmpty && emptyMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  emptyMessage,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w600),
                ),
              ] else ...[
                const SizedBox(height: 10),
                Text(l10n.top10, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                for (int i = 0; i < lb.top.length; i++) ...[
                  Builder(builder: (context) {
                    final row = lb.top[i];
                    final isMe = row.userId == uid;
                    // If user updates nickname, the public profile stream updates immediately,
                    // but the leaderboard row.nickname can lag (server-side rebuild).
                    // Prefer myNickname for my own row so UI reflects instantly without navigation.
                    final name = isMe ? myName : _displayNameFor(userId: row.userId, nickname: row.nickname);
                    final suffix = showSolvedFailed && row.solved != null && row.failed != null
                        ? ' ${l10n.solvedFailedCount(row.solved!, row.failed!)}'
                        : '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(
                              '${i + 1}.',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isMe ? Colors.blue.shade700 : Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isMe ? FontWeight.w900 : FontWeight.w600,
                                color: isMe ? Colors.blue.shade700 : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${row.score}${isJa ? '点' : ' pts'}$suffix',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: isMe ? Colors.blue.shade700 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildExerciseHeader({required BuildContext context, required bool isSolved, required int count}) {
    final l10n = AppLocalizations.of(context);
    final color = isSolved ? Colors.green : Colors.red;
    final icon = isSolved ? Icons.check_circle : Icons.cancel;
    final label = isSolved ? l10n.correctProblems : l10n.incorrectProblems;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withAlpha(31),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withAlpha(89), width: 1),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  int _getOverallFilterCount(GachaFilterMode mode) {
    switch (mode) {
      case GachaFilterMode.excludeSolvedGE1:
        return 1;
      case GachaFilterMode.excludeSolvedGE2:
        return 2;
      case GachaFilterMode.excludeSolvedGE3:
        return 3;
      case GachaFilterMode.random:
        return 1; // joymathの集計UIと同様に「最新1回」として扱う
      default:
        return 0;
    }
  }

  Widget _buildOverallStarBadge() {
    return const Text(
      '⭐️',
      style: TextStyle(fontSize: 24),
    );
  }

  Widget _buildOverallStarBadges(double progressRate01) {
    final r = progressRate01.clamp(0.0, 1.0);
    if (r <= 0.2 + _overallStarEpsilon) {
      return const SizedBox.shrink();
    }

    int starCount;
    if (r < 0.4) {
      starCount = 1;
    } else if (r < 0.6) {
      starCount = 2;
    } else if (r < 0.8) {
      starCount = 3;
    } else if (r < 1.0) {
      starCount = 4;
    } else {
      starCount = 5;
    }

    if (starCount == 5) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOverallStarBadge(),
              const SizedBox(width: 2),
              _buildOverallStarBadge(),
            ],
          ),
          const SizedBox(height: 0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOverallStarBadge(),
              const SizedBox(width: 2),
              _buildOverallStarBadge(),
              const SizedBox(width: 2),
              _buildOverallStarBadge(),
            ],
          ),
        ],
      );
    } else if (starCount == 4) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOverallStarBadge(),
              const SizedBox(width: 2),
              _buildOverallStarBadge(),
            ],
          ),
          const SizedBox(height: 0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOverallStarBadge(),
              const SizedBox(width: 2),
              _buildOverallStarBadge(),
            ],
          ),
        ],
      );
    } else if (starCount == 3) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOverallStarBadge(),
              const SizedBox(width: 2),
              _buildOverallStarBadge(),
            ],
          ),
          const SizedBox(height: 0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOverallStarBadge(),
            ],
          ),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(starCount, (index) {
          return Padding(
            padding: EdgeInsets.only(left: index > 0 ? 2 : 0),
            child: _buildOverallStarBadge(),
          );
        }),
      );
    }
  }

  Widget _buildOverallRainbowAndStars({
    required int totalExcluded,
    required int totalProblems,
  }) {
    final filterCount = _getOverallFilterCount(widget.gachaFilterMode);
    final progressRate01 = totalProblems > 0 ? (totalExcluded / totalProblems) : 0.0;

    // 虹はフィルタが有効(1..3)かつ達成率が0より大きい時だけ
    final showRainbow = filterCount > 0 && filterCount <= 3 && progressRate01 > 0;

    // 星の段組を決めるために starCount 相当を計算
    int starCount = 0;
    if (progressRate01 > 0.2) {
      if (progressRate01 < 0.4) {
        starCount = 1;
      } else if (progressRate01 < 0.6) {
        starCount = 2;
      } else if (progressRate01 < 0.8) {
        starCount = 3;
      } else if (progressRate01 < 1.0) {
        starCount = 4;
      } else {
        starCount = 5;
      }
    }
    final isTwoRows = starCount >= 3;

    // 背景の白い四角は無し：虹＋星のみをコンパクトに中央寄せ
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SizedBox(
        width: double.infinity,
        height: isTwoRows ? 62 : 44,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (showRainbow)
              Opacity(
                opacity: 0.5,
                child: Image.asset(
                  'assets/background/rainbow$filterCount.png',
                  width: 86,
                  fit: BoxFit.contain,
                ),
              ),
            Center(child: _buildOverallStarBadges(progressRate01)),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleCell(BuildContext context, UnitCategory category) {
    final l10n = AppLocalizations.of(context);
    final result = _results[category];
    final percentage = result?.percentage ?? 0.0;
    final titleInfo = _getTitleByCompletionRate(context: context, category: category, percentageRaw: percentage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: getCategoryColor(category),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_getCategoryName(category, l10n)} Lv${titleInfo.level}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            titleInfo.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildTitlePairRow(
    BuildContext context, {
    required UnitCategory left,
    required UnitCategory right,
  }) {
    return Row(
      children: [
        Expanded(child: _buildTitleCell(context, left)),
        const SizedBox(width: 12),
        Expanded(child: _buildTitleCell(context, right)),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _timerManager = widget.timerManager ?? TimerManager();
    _loadData();
    // 学習履歴が変わったら（解答/履歴編集/同期マージ）達成率等を再計算して反映する
    _learningEpochListener = () {
      _learningEpochDebounce?.cancel();
      _learningEpochDebounce = Timer(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        _loadData();
      });
    };
    SimpleDataManager.learningDataEpochListenable.addListener(_learningEpochListener!);
    // Non-blocking: try syncing queued attempt events after the first frame, then refresh ranking UI.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(() async {
        try {
          final last = await SimpleDataManager.loadLastUnitGachaAttemptSyncResult();
          final q = await SimpleDataManager.getUnitGachaAttemptQueueLength();
          if (!mounted) return;
          setState(() {
            _lastAttemptSync = last ?? _lastAttemptSync;
            _attemptQueueLen = q;
          });
        } catch (_) {}
      }());
      _kickoffRankingBackgroundRefresh(reason: 'page_open', bestEffortWeeklyRetry: true);
    });
  }

  @override
  void dispose() {
    _learningEpochDebounce?.cancel();
    final l = _learningEpochListener;
    if (l != null) {
      SimpleDataManager.learningDataEpochListenable.removeListener(l);
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final results = <UnitCategory, CompletionRateResult>{};

    try {
      // 各カテゴリーの達成率を計算
      for (final category in UnitCategory.values) {
        final result = await CompletionRateCalculator.calculateCompletionRate(
          category: category,
          gachaFilterMode: widget.gachaFilterMode,
          selectedCategories: widget.selectedCategories,
        );
        results[category] = result;
      }

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e, _) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getCategoryName(UnitCategory category, AppLocalizations l10n) {
    switch (category) {
      case UnitCategory.mechanics:
        return l10n.categoryLabelMechanics;
      case UnitCategory.thermodynamics:
        return l10n.categoryLabelThermodynamics;
      case UnitCategory.waves:
        return l10n.categoryLabelWaves;
      case UnitCategory.electromagnetism:
        return l10n.categoryLabelElectromagnetism;
      case UnitCategory.atom:
        return l10n.categoryLabelAtom;
    }
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return UnitGachaCommonHeader(
      timerManager: _timerManager,
      l10n: l10n,
      isHelpPageVisible: widget.isHelpPageVisible,
      isProblemListVisible: widget.isProblemListVisible,
      isReferenceTableVisible: widget.isReferenceTableVisible,
      isScratchPaperMode: widget.isScratchPaperMode,
      showFilterSettings: widget.showFilterSettings,
      onHelpToggle: widget.onHelpToggle ?? widget.onClose,
      onProblemListToggle: widget.onProblemListToggle ?? widget.onClose,
      onReferenceTableToggle: widget.onReferenceTableToggle ?? widget.onClose,
      onScratchPaperToggle: widget.onScratchPaperToggle ?? widget.onClose,
      onFilterToggle: widget.onFilterToggle ?? () {},
      onLoginTap: widget.onLoginTap,
      onDataAnalysisNavigate: widget.onDataAnalysisNavigate ?? widget.onClose,
      isDataAnalysisActive: widget.isDataAnalysisActive,
      isAuthPageVisible: false,
      disableTimer: true,
      disableFilter: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _ensureLeaderboardFutures();
    final uid = _userId;
    final profileStream = uid == null ? null : FirestorePublicProfileService.watchUnitGachaProfile(userId: uid);

    return Scaffold(
      body: Stack(
        children: [
          // ヘルプページ同様、ヘッダー2行目まで背景を表示
          const Positioned.fill(child: BackgroundImageWidget()),
          SafeArea(
            child: Column(
              children: [
                // ヘッダー
                _buildHeader(context),
                // ヘッダー直下の余白（背景画像が少し見えるように）
                const SizedBox(height: 10),
                // コンテンツ（背景色は従来通り）
                Expanded(
                  child: Container(
                    color: Colors.grey[50],
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            child: (profileStream == null)
                                ? _buildContent(context, l10n, myNickname: null)
                                : StreamBuilder<UnitGachaPublicProfile>(
                                    stream: profileStream,
                                    builder: (context, snapshot) {
                                      final myNickname = snapshot.data?.nickname;
                                      return _buildContent(context, l10n, myNickname: myNickname);
                                    },
                                  ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n, {required String? myNickname}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                                // 先頭の余白（上のヘッダー余白と合わせて過剰にならないよう控えめに）
                                const SizedBox(height: 8),
                                // 総合データセクション
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        l10n.overallData,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      _buildRankingList(
                                        title: l10n.overallRanking,
                                        showSolvedFailed: false,
                                        future: _overallLeaderboardFuture,
                                        myNickname: myNickname,
                                      ),
                                      const SizedBox(height: 10),
                                      if (widget.gachaFilterMode == GachaFilterMode.random) ...[
                                        Text(
                                          l10n.randomModeNote,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      const SizedBox(height: 2),
                                      _buildTitlePairRow(
                                        context,
                                        left: UnitCategory.mechanics,
                                        right: UnitCategory.thermodynamics,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildTitlePairRow(
                                        context,
                                        left: UnitCategory.waves,
                                        right: UnitCategory.electromagnetism,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildTitleCell(context, UnitCategory.atom),
                                      const SizedBox(height: 16),
                                      _buildRoundedSubtitle(l10n.completionRate),
                                      const SizedBox(height: 16),
                                      Builder(
                                        builder: (context) {
                                          final totalExcluded = UnitCategory.values.fold<int>(
                                            0,
                                            (sum, c) => sum + (_results[c]?.completedCount ?? 0),
                                          );
                                          final totalProblems = UnitCategory.values.fold<int>(
                                            0,
                                            (sum, c) => sum + (_results[c]?.totalCount ?? 0),
                                          );

                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              // joymath Homeの進捗UIを参考にした「虹＋星」（ミニ版）
                                              _buildOverallRainbowAndStars(
                                                totalExcluded: totalExcluded,
                                                totalProblems: totalProblems,
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                '$totalExcluded / $totalProblems',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Builder(builder: (context) {
                                                final filterCount = _getOverallFilterCount(widget.gachaFilterMode);
                                                final style = TextStyle(fontSize: 13, color: Colors.grey[600]);

                                                if (filterCount <= 0) {
                                                  return Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                                      const SizedBox(width: 6),
                                                      Text(l10n.excludedMarkedProblemsNoCount, style: style),
                                                    ],
                                                  );
                                                }

                                                return Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(l10n.excludedMarkedProblemsPrefix(filterCount), style: style),
                                                    const SizedBox(width: 6),
                                                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                                    const SizedBox(width: 6),
                                                    Text(l10n.excludedMarkedProblemsSuffix(filterCount), style: style),
                                                  ],
                                                );
                                              }),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      CompletionRateBarChart(
                                        results: _results,
                                        l10n: l10n,
                                      ),
                                    ],
                                  ),
                                ),
                                // 週間データセクション
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    // 赤系だと不正解（赤）背景と被るので、週間セクションは薄い黄色にする
                                    color: Colors.yellow.shade50,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        l10n.weeklyData,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      // ランキング（見出し直下）
                                      _buildRankingList(
                                        title: l10n.weeklyRanking,
                                        showSolvedFailed: false,
                                        future: _weeklyLeaderboardFutureCache[_weekKeyForOffset(_currentWeekOffset)],
                                        myNickname: myNickname,
                                        emptyMessage: l10n.weeklyRankingNoData,
                                      ),
                                      const SizedBox(height: 16),
                                      // 期間レンジ表示（日付選択付き）
                                      Builder(
                                        builder: (context) {
                                          final weekRange = WeeklyProblemStatistics.getWeekRange(_currentWeekOffset);
                                          return Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.chevron_left),
                                                onPressed: () {
                                                  final next = _currentWeekOffset - 1;
                                                  setState(() {
                                                    _currentWeekOffset = next;
                                                    _refreshWeeklyLeaderboardForOffset(next);
                                                  });
                                                },
                                              ),
                                              Text(
                                                '${DateFormat('yyyy/M/d').format(weekRange.start)} - ${DateFormat('yyyy/M/d').format(weekRange.end)}',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.chevron_right),
                                                onPressed: () {
                                                  final next = _currentWeekOffset + 1;
                                                  setState(() {
                                                    _currentWeekOffset = next;
                                                    _refreshWeeklyLeaderboardForOffset(next);
                                                  });
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      // 解いた問題数
                                      _buildRoundedSubtitle(l10n.weeklyProblemsSolved),
                                      const SizedBox(height: 16),
                                      WeeklyProblemChart(
                                        weekOffset: _currentWeekOffset,
                                        showDateSelector: false,
                                        onWeekOffsetChanged: (newOffset) {
                                          setState(() {
                                            _currentWeekOffset = newOffset;
                                            _refreshWeeklyLeaderboardForOffset(newOffset);
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                      // 1週間で解いた分野内訳（表記変更）
                                      _buildRoundedSubtitle(l10n.weeklyCategoryBreakdown),
                                      const SizedBox(height: 36),
                                      WeeklyCategoryPieChart(
                                        weekOffset: _currentWeekOffset,
                                      ),
                                      const SizedBox(height: 24),
                                      // 分野ごとの正答率（表記変更）
                                      _buildRoundedSubtitle(l10n.weeklyCategoryAccuracy),
                                      const SizedBox(height: 16),
                                      WeeklyAccuracyChart(
                                        weekOffset: _currentWeekOffset,
                                      ),
                                      const SizedBox(height: 24),
                                      // 演習データ（正解/不正解の数式リスト）
                                      _buildRoundedSubtitle(l10n.weeklyExerciseData),
                                      const SizedBox(height: 16),
                                      FutureBuilder<
                                          ({
                                            List<WeeklyExerciseRecord> solved,
                                            List<WeeklyExerciseRecord> failed
                                          })>(
                                        future: WeeklyProblemStatistics
                                            .calculateWeeklyExerciseRecords(
                                          _currentWeekOffset,
                                        ),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(24),
                                                child: CircularProgressIndicator(),
                                              ),
                                            );
                                          }

                                          final solved = snapshot.data!.solved;
                                          final failed = snapshot.data!.failed;
                                          final l10n = AppLocalizations.of(context);

                                          Widget buildList(List<WeeklyExerciseRecord> items,
                                              {required String emptyText}) {
                                            if (items.isEmpty) {
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                child: Text(
                                                  emptyText,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              );
                                            }

                                            // 新しい順のitemsをカテゴリごとに分割（カテゴリ内でも新しい順を維持）
                                            final byCategory = <UnitCategory, List<WeeklyExerciseRecord>>{};
                                            for (final c in UnitCategory.values) {
                                              byCategory[c] = <WeeklyExerciseRecord>[];
                                            }
                                            for (final r in items) {
                                              (byCategory[r.category] ??= <WeeklyExerciseRecord>[]).add(r);
                                            }

                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                for (final category in UnitCategory.values) ...[
                                                  if ((byCategory[category] ?? const []).isNotEmpty) ...[
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 8, bottom: 6),
                                                      child: Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 5,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: getCategoryColor(category).withAlpha(31),
                                                            borderRadius: BorderRadius.circular(10),
                                                            border: Border.all(
                                                              color: getCategoryColor(category).withAlpha(140),
                                                              width: 1,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            _getCategoryName(category, l10n),
                                                            textAlign: TextAlign.left,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w800,
                                                              color: getCategoryColor(category),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    ...byCategory[category]!.map((r) {
                                                      final exprTex = formatExpression(r.expr);
                                                      final unitTex =
                                                          r'\left[' + formatUnitString(r.answer) + r'\right]';
                                                      final exprTexDisplay =
                                                          r'\displaystyle ' + exprTex;
                                                      final unitTexDisplay =
                                                          r'\displaystyle ' + unitTex;

                                                      return Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 3),
                                                        child: Align(
                                                          alignment: Alignment.centerLeft,
                                                          child: SingleChildScrollView(
                                                            scrollDirection: Axis.horizontal,
                                                            physics: const ClampingScrollPhysics(),
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              children: [
                                                                Math.tex(
                                                                  exprTexDisplay,
                                                                  mathStyle: MathStyle.text,
                                                                  textStyle: const TextStyle(
                                                                    fontSize: 18,
                                                                    color: Colors.black,
                                                                    fontFamily: 'serif',
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 6),
                                                                const Text(
                                                                  ':',
                                                                  style: TextStyle(
                                                                    fontSize: 18,
                                                                    fontWeight: FontWeight.w600,
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 6),
                                                                Math.tex(
                                                                  unitTexDisplay,
                                                                  mathStyle: MathStyle.text,
                                                                  textStyle: const TextStyle(
                                                                    fontSize: 18,
                                                                    color: Colors.blue,
                                                                    fontFamily: 'serif',
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                                  ],
                                                ],
                                              ],
                                            );
                                          }

                                          // 白いカード背景は使わず、左右を赤/緑の面として出す（仕切り線なしで密着）
                                          return Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      // 左: 不正解（赤背景）
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red.shade50,
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: SingleChildScrollView(
                                                          scrollDirection: Axis.horizontal,
                                                          physics: const ClampingScrollPhysics(),
                                                          child: ConstrainedBox(
                                                            constraints: const BoxConstraints(minWidth: 0),
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                _buildExerciseHeader(
                                                                  context: context,
                                                                  isSolved: false,
                                                                  count: failed.length,
                                                                ),
                                                                const SizedBox(height: 10),
                                                                buildList(
                                                                  failed,
                                                                  emptyText: l10n.noFailedThisWeek,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      // 右: 正解（緑背景）
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                        decoration: BoxDecoration(
                                                          color: Colors.green.shade50,
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: SingleChildScrollView(
                                                          scrollDirection: Axis.horizontal,
                                                          physics: const ClampingScrollPhysics(),
                                                          child: ConstrainedBox(
                                                            constraints: const BoxConstraints(minWidth: 0),
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                _buildExerciseHeader(
                                                                  context: context,
                                                                  isSolved: true,
                                                                  count: solved.length,
                                                                ),
                                                                const SizedBox(height: 10),
                                                                buildList(
                                                                  solved,
                                                                  emptyText: l10n.noCorrectThisWeek,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
    );
  }
}




