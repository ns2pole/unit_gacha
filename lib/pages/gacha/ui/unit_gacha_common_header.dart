// lib/pages/gacha/ui/unit_gacha_common_header.dart
// ユニットガチャ共通ヘッダーウィジェット

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../localization/app_localizations.dart';
import '../../../managers/timer_manager.dart';
import '../../../widgets/timer/timer_toggle.dart';
import '../../common/tablet_utils.dart';
import '../auth/auth_sync.dart' show UnitGachaSyncButton;
import '../../../services/problems/simple_data_manager.dart';
import '../../../services/auth/firebase_auth_service.dart';
import '../logic/unit_gacha_filter.dart' show UnitGachaFilterHelper;

/// ユニットガチャ共通ヘッダーウィジェット
class UnitGachaCommonHeader extends StatelessWidget {
  // Home（共通ヘッダー）のアイコンボタンサイズ。縦長に見えないよう少しだけ小さくする。
  static const double _iconButtonSize = 44;
  final TimerManager timerManager;
  final AppLocalizations l10n;
  final bool isHelpPageVisible;
  final bool isProblemListVisible;
  final bool isReferenceTableVisible;
  final bool isScratchPaperMode;
  final bool showFilterSettings;
  final VoidCallback onHelpToggle;
  final VoidCallback onProblemListToggle;
  final VoidCallback onReferenceTableToggle;
  final VoidCallback onScratchPaperToggle;
  final VoidCallback onFilterToggle;
  final VoidCallback? onLoginTap;
  final VoidCallback? onDataAnalysisNavigate;
  final bool isDataAnalysisActive;
  final bool isAuthPageVisible;
  final Widget? filterSettingsPanel;
  final bool showFilterPanel;
  final bool disableTimer;
  final bool disableFilter;
  // Home icon guide (optional)
  final Key? helpButtonKey;
  final Key? cloudButtonKey;
  final Key? timerButtonKey;
  final Key? filterButtonKey;
  final Key? referenceButtonKey;
  final Key? scratchPaperButtonKey;
  final Key? problemListButtonKey;
  final Key? dataAnalysisButtonKey;

  const UnitGachaCommonHeader({
    Key? key,
    required this.timerManager,
    required this.l10n,
    required this.isHelpPageVisible,
    required this.isProblemListVisible,
    required this.isReferenceTableVisible,
    required this.isScratchPaperMode,
    required this.showFilterSettings,
    required this.onHelpToggle,
    required this.onProblemListToggle,
    required this.onReferenceTableToggle,
    required this.onScratchPaperToggle,
    required this.onFilterToggle,
    this.onLoginTap,
    this.onDataAnalysisNavigate,
    this.isDataAnalysisActive = false,
    this.isAuthPageVisible = false,
    this.filterSettingsPanel,
    this.showFilterPanel = false,
    this.disableTimer = false,
    this.disableFilter = false,
    this.helpButtonKey,
    this.cloudButtonKey,
    this.timerButtonKey,
    this.filterButtonKey,
    this.referenceButtonKey,
    this.scratchPaperButtonKey,
    this.problemListButtonKey,
    this.dataAnalysisButtonKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isTablet = TabletUtils.isTablet(context);

    // ログイン状態に応じたアイコンを取得
    return StreamBuilder(
      stream: FirebaseAuthService.authStateChanges,
      builder: (context, snapshot) {
        final isAuthenticated = FirebaseAuthService.isAuthenticated;
        final userEmail = FirebaseAuthService.userEmail;
        final userPhoneNumber = FirebaseAuthService.userPhoneNumber;
        final displayName = FirebaseAuthService.displayName;
        final loginMethod = FirebaseAuthService.loginMethod;

        // アカウント情報を取得
        String? accountInfo;
        if (isAuthenticated) {
          if (userPhoneNumber != null && userPhoneNumber.isNotEmpty) {
            accountInfo = userPhoneNumber;
          } else if (userEmail != null && userEmail.isNotEmpty) {
            accountInfo = userEmail;
          } else if (displayName != null && displayName.isNotEmpty) {
            accountInfo = displayName;
          }
        }

        if (isTablet) {
          // iPadの場合：1行目にタイトル、2行目に6つのボタン
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              // 1行目：Stackで中央にタイトル、左端に?ボタン、右端にクラウドボタン
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 中央：タイトル
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Unit Gacha',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8B7355),
                                ),
                              ),
                            ],
                          ),
                          // 左端：?ボタン
                          Positioned(
                            left: 0,
                            child: KeyedSubtree(
                              key: helpButtonKey,
                              child: _buildCircleIconButton(
                                icon: Icons.help_outline,
                                active: isHelpPageVisible,
                                tooltip: isHelpPageVisible
                                    ? l10n.tooltipCloseHelp
                                    : l10n.tooltipHelp,
                                onTap: onHelpToggle,
                              ),
                            ),
                          ),
                          // 右端：クラウドボタン
                          Positioned(
                            right: 0,
                            child: KeyedSubtree(
                              key: cloudButtonKey,
                              child: isAuthenticated
                                  ? _buildCloudMenuButton(context, accountInfo, loginMethod)
                                  : _buildLoginButton(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // 2行目：ボタン（狭い幅では折り返してオーバーフロー回避）
              _buildControlRow(context),
              if (showFilterPanel && filterSettingsPanel != null) ...[
                const SizedBox(height: 12),
                filterSettingsPanel!,
              ],
            ],
          );
        } else {
          // スマホの場合：タイトルと6つのアイコンを中央に配置、雲アイコンと同期ボタンは絶対配置
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 中央：タイトル
                          const Text(
                            'Unit Gacha',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B7355),
                            ),
                          ),
                          // 左端：?ボタン
                          Positioned(
                            left: 0,
                            child: KeyedSubtree(
                              key: helpButtonKey,
                              child: _buildCircleIconButton(
                                icon: Icons.help_outline,
                                active: isHelpPageVisible,
                                tooltip: isHelpPageVisible
                                    ? l10n.tooltipCloseHelp
                                    : l10n.tooltipHelp,
                                onTap: onHelpToggle,
                              ),
                            ),
                          ),
                          // 右端：雲アイコン/ログインボタン
                          Positioned(
                            right: 0,
                            child: KeyedSubtree(
                              key: cloudButtonKey,
                              child: isAuthenticated
                                  ? _buildCloudMenuButton(context, accountInfo, loginMethod)
                                  : _buildLoginButton(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // 2行目：ボタン（狭い幅では折り返してオーバーフロー回避）
              _buildControlRow(context),
              if (showFilterPanel && filterSettingsPanel != null) ...[
                const SizedBox(height: 12),
                filterSettingsPanel!,
              ],
            ],
          );
        }
      },
    );
  }

  Widget _buildControlRow(BuildContext context) {
    // ?ボタンは1行目に移動したので、残りの6つのアイコンを等間隔で配置
    final List<Widget> buttons = [
      KeyedSubtree(
        key: timerButtonKey,
        child: disableTimer
            ? Opacity(
                opacity: 0.5,
                child: IgnorePointer(
                  child: TimerToggle(timerManager: timerManager),
                ),
              )
            : TimerToggle(timerManager: timerManager),
      ),
      disableFilter
          ? Opacity(
              opacity: 0.5,
              child: IgnorePointer(
                child: KeyedSubtree(
                  key: filterButtonKey,
                  child: _buildCircleIconButton(
                    icon: Icons.filter_alt,
                    active: false,
                    tooltip: l10n.tooltipShowFilter,
                    onTap: () {},
                  ),
                ),
              ),
            )
          : KeyedSubtree(
              key: filterButtonKey,
              child: _buildCircleIconButton(
                icon: Icons.filter_alt,
                active: showFilterSettings,
                tooltip: showFilterSettings ? l10n.tooltipHideFilter : l10n.tooltipShowFilter,
                onTap: onFilterToggle,
              ),
            ),
      KeyedSubtree(
        key: referenceButtonKey,
        child: _buildCircleIconButton(
          icon: Icons.science,
          active: isReferenceTableVisible,
          tooltip: isReferenceTableVisible
              ? l10n.tooltipCloseReferenceTable
              : l10n.tooltipReferenceTable,
          onTap: onReferenceTableToggle,
        ),
      ),
      KeyedSubtree(
        key: scratchPaperButtonKey,
        child: _buildCircleIconButton(
          icon: Icons.edit_note,
          active: isScratchPaperMode,
          tooltip: isScratchPaperMode
              ? l10n.tooltipScratchPaperClose
              : l10n.tooltipScratchPaperOpen,
          onTap: onScratchPaperToggle,
        ),
      ),
      KeyedSubtree(
        key: problemListButtonKey,
        child: _buildSquareIconButton(
          icon: Icons.list_alt,
          active: isProblemListVisible,
          tooltip: isProblemListVisible
              ? l10n.tooltipCloseProblemList
              : l10n.tooltipProblemList,
          onTap: onProblemListToggle,
        ),
      ),
    ];
    
    // データ分析ボタンがある場合は追加
    if (onDataAnalysisNavigate != null) {
      buttons.add(
        KeyedSubtree(
          key: dataAnalysisButtonKey,
          child: _buildCircleIconButton(
            icon: Icons.analytics_outlined,
            active: isDataAnalysisActive,
            tooltip: isDataAnalysisActive
                ? l10n.tooltipCloseDataAnalysis
                : l10n.tooltipDataAnalysis,
            onTap: onDataAnalysisNavigate!,
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runAlignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: buttons,
      ),
    );
  }

  Widget _buildCloudMenuButton(
    BuildContext context,
    String? accountInfo,
    String? loginMethod,
  ) {
    return PopupMenuButton<String>(
      iconSize: 42.0,
      icon: ValueListenableBuilder<int>(
        valueListenable: SimpleDataManager.cloudSyncInFlightListenable,
        builder: (context, inFlight, _) {
          final isSyncing = inFlight > 0;
          if (isSyncing) {
            return SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
            );
          }
          return Icon(
            Icons.cloud,
            color: Colors.blue.shade600,
            size: 42.0,
          );
        },
      ),
      onSelected: (value) async {
        if (value == 'sync') {
          await _performSync(context);
        } else if (value == 'logout') {
          await FirebaseAuthService.signOut();
          if (context.mounted) {
            // 成功メッセージを表示
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.loggedOut),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      itemBuilder: (context) => [
        if (accountInfo != null)
          PopupMenuItem(
            enabled: false,
            child: Text(
              accountInfo,
              style: TextStyle(fontWeight: FontWeight.bold),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        if (loginMethod != null)
          PopupMenuItem(
            enabled: false,
            child: Row(
              children: [
                Icon(Icons.login, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.cloudUsingWithMethod(loginMethod!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'sync',
          child: Row(
            children: [
              const Icon(Icons.cloud_sync, size: 20),
              const SizedBox(width: 8),
              Text(l10n.popupSyncWithCloud),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 20),
              const SizedBox(width: 8),
              Text(l10n.popupLogout),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _performSync(BuildContext context) async {
    try {
      await Future.wait([
        SimpleDataManager.syncLocalDataToFirestore(),
        SimpleDataManager.syncLocalSettingsToFirestore(),
      ], eagerError: false);
      
      try {
        await SimpleDataManager.initialize();
      } catch (e) {
        print('Warning: Error initializing from Firestore: $e');
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cloudSyncCompleted),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error syncing: $e');
      if (context.mounted) {
        final errorStr = e.toString().toLowerCase();
        final message = errorStr.contains('permission')
            ? l10n.cloudSyncPermissionDenied
            : l10n.cloudSyncPartialError;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildLoginButton(BuildContext context) {
    return _buildCircleIconButton(
      icon: Icons.cloud_outlined,
      active: isAuthPageVisible,
      tooltip: isAuthPageVisible ? l10n.tooltipCloseLogin : l10n.tooltipLogin,
      onTap: onLoginTap ?? () {},
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: _iconButtonSize,
          height: _iconButtonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.orange.shade100 : Colors.grey.shade200,
            border: Border.all(
              color: active ? Colors.orange.shade400 : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            size: 28,
            color: active ? Colors.orange.shade700 : Colors.grey.shade600,
          ),
        ),
      ),
    );

    if (tooltip == null) {
      return button;
    }

    return Tooltip(
      message: tooltip,
      child: button,
    );
  }

  Widget _buildSquareIconButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: _iconButtonSize,
          height: _iconButtonSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: active ? Colors.orange.shade100 : Colors.grey.shade200,
            border: Border.all(
              color: active ? Colors.orange.shade400 : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            size: 28,
            color: active ? Colors.orange.shade700 : Colors.grey.shade600,
          ),
        ),
      ),
    );

    if (tooltip == null) {
      return button;
    }

    return Tooltip(
      message: tooltip,
      child: button,
    );
  }
}
