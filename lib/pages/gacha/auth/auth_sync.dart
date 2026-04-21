// lib/pages/gacha/auth/auth_sync.dart
// 単位ガチャページの認証・同期関連

import 'package:flutter/material.dart';
import '../../../services/auth/firebase_auth_service.dart';
import '../../../services/auth/firestore_public_profile_service.dart';
import '../../../services/problems/simple_data_manager.dart';
import '../../../localization/app_localizations.dart';
import '../../other/auth_page.dart';

/// Firebaseクラウドデータとの同期ボタン
class UnitGachaSyncButton extends StatefulWidget {
  final bool enabled;

  const UnitGachaSyncButton({Key? key, this.enabled = true}) : super(key: key);

  @override
  State<UnitGachaSyncButton> createState() => _UnitGachaSyncButtonState();
}

class _UnitGachaSyncButtonState extends State<UnitGachaSyncButton> {
  bool _isSyncing = false;

  Future<void> _performSync() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      final l10n = AppLocalizations.of(context);
      await Future.wait([
        SimpleDataManager.syncLocalDataToFirestore(),
        SimpleDataManager.syncLocalSettingsToFirestore(),
      ], eagerError: false);

      if (mounted) {
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
      if (mounted) {
        final l10n = AppLocalizations.of(context);
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
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled && !_isSyncing;
    final iconColor = isEnabled ? Color(0xFF8B7355) : Colors.grey.shade400;
    final l10n = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: IconButton(
        iconSize: 42.0,
        icon: ValueListenableBuilder<int>(
          valueListenable: SimpleDataManager.cloudSyncInFlightListenable,
          builder: (context, inFlight, _) {
            final syncing = _isSyncing || inFlight > 0;
            return syncing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF8B7355),
                      ),
                    ),
                  )
                : Icon(Icons.cloud_sync, color: iconColor, size: 42.0);
          },
        ),
        onPressed: isEnabled ? _performSync : null,
        tooltip: isEnabled
            ? l10n.cloudSyncTooltipSync
            : l10n.cloudSyncTooltipLoginRequired,
      ),
    );
  }
}

/// 認証状態に応じたクラウドボタンと同期ボタンを構築
class UnitGachaAuthCloudButtons extends StatelessWidget {
  const UnitGachaAuthCloudButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuthService.authStateChanges,
      builder: (context, snapshot) {
        final isAuthenticated = FirebaseAuthService.isAuthenticated;
        final accountInfo = _getAccountInfo();
        final loginMethod = FirebaseAuthService.loginMethod;

        if (isAuthenticated) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const UnitGachaSyncButton(),
              buildCloudMenuButton(context, accountInfo, loginMethod),
            ],
          );
        } else {
          return Align(
            alignment: Alignment.centerRight,
            child: buildLoginButton(context),
          );
        }
      },
    );
  }

  String? _getAccountInfo() {
    final userPhoneNumber = FirebaseAuthService.userPhoneNumber;
    final userEmail = FirebaseAuthService.userEmail;
    final displayName = FirebaseAuthService.displayName;

    if (userPhoneNumber != null && userPhoneNumber.isNotEmpty) {
      return userPhoneNumber;
    } else if (userEmail != null && userEmail.isNotEmpty) {
      return userEmail;
    } else if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    return null;
  }
}

/// クラウドメニューボタンを構築（共通関数）
Widget buildCloudMenuButton(
  BuildContext context,
  String? accountInfo,
  String? loginMethod,
) {
  final l10n = AppLocalizations.of(context);
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
        return Icon(Icons.cloud, color: Colors.blue.shade600, size: 42.0);
      },
    ),
    onSelected: (value) async {
      if (value == 'sync') {
        await _performSync(context);
      } else if (value == 'logout') {
        final shouldLogout = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: Text(l10n.rankingLogoutConfirmTitle),
              content: Text(l10n.rankingLogoutConfirmBody),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.rankingLogoutConfirmTitle),
                ),
              ],
            );
          },
        );

        if (shouldLogout != true) return;
        if (!context.mounted) return;

        // Best-effort: disable ranking participation BEFORE sign-out.
        final uid = FirebaseAuthService.userId;
        if (uid != null) {
          try {
            await FirestorePublicProfileService.setUnitGachaParticipating(
              userId: uid,
              participating: false,
            );
          } catch (_) {}
        }

        await FirebaseAuthService.signOut();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.rankingLogoutDoneMessage),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
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
                  l10n.cloudUsingWithMethod(loginMethod),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
  final l10n = AppLocalizations.of(context);
  try {
    await Future.wait([
      SimpleDataManager.syncLocalDataToFirestore(),
      SimpleDataManager.syncLocalSettingsToFirestore(),
    ], eagerError: false);

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

/// ログインボタンを構築（共通関数）
Widget buildLoginButton(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return Material(
    color: Colors.transparent,
    child: IconButton(
      iconSize: 42.0,
      icon: Icon(Icons.cloud_outlined, color: Color(0xFF8B7355), size: 42.0),
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AuthPage()),
        );
        if (result == true && context.mounted) {
          // 状態更新が必要な場合は親ウィジェットで処理
        }
      },
      tooltip: l10n.tooltipLogin,
    ),
  );
}
