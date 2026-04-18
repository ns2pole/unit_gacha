// lib/utils/update_checker.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../localization/app_locale.dart';
import '../util/platform_info.dart';
// import '../l10n/app_localizations.dart'; // unitGachaでは未実装

/// UpdateChecker
/// - navigatorKey: MaterialApp に渡している GlobalKey<NavigatorState> をそのまま渡すこと
/// - forceShowForDebug: true にするとストア情報が無くてもダイアログを出します（開発用）
class UpdateChecker {
  final String iosId;
  final String androidId;
  final GlobalKey<NavigatorState> navigatorKey;
  final int skipDays;
  final String title;
  final String message;
  final String laterText;
  final String updateText;
  final bool forceShowForDebug;

  /// 内部設定（リトライ回数・待ち時間）-- 必要なら調整可能
  final int _maxRetries;
  final Duration _retryDelay;

  UpdateChecker({
    required this.iosId,
    required this.androidId,
    required this.navigatorKey,
    this.skipDays = 3,
    this.title = "新しいアップデートがあります",
    this.message = "更新してみませんか？",
    this.laterText = "あとで",
    this.updateText = "更新する",
    this.forceShowForDebug = false,
    int maxRetries = 10,
    Duration retryDelay = const Duration(milliseconds: 200),
  })  : _maxRetries = maxRetries,
        _retryDelay = retryDelay;

  /// アプリ起動時に一度呼ぶ想定。WidgetsBinding.instance.addPostFrameCallback の内外どちらでも可。
  void checkOnAppStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('[UpdateChecker] checkOnAppStart: called');
      try {
        await _checkAndShowDialog();
      } catch (e, st) {
        debugPrint('[UpdateChecker] checkOnAppStart: error -> $e');
        debugPrint(st.toString());
      }
      debugPrint('[UpdateChecker] checkOnAppStart: done');
    });
  }

  Future<void> _checkAndShowDialog() async {
    debugPrint('[UpdateChecker] _checkAndShowDialog: start');
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();

    // 前回表示日確認（ただしデバッグ強制表示時は無視）
    final lastShownMillis = prefs.getInt("last_update_prompt_millis");
    debugPrint('[UpdateChecker] lastShownMillis = $lastShownMillis, skipDays = $skipDays, today = $today');

    if (lastShownMillis != null && !forceShowForDebug) {
      final lastShown = DateTime.fromMillisecondsSinceEpoch(lastShownMillis);
      debugPrint('[UpdateChecker] lastShown = $lastShown');
      if (today.difference(lastShown).inDays < skipDays) {
        debugPrint('[UpdateChecker] skipping check: within skipDays');
        return;
      }
    }

    final newVersion = NewVersionPlus(iOSId: iosId, androidId: androidId);

    try {
      debugPrint('[UpdateChecker] calling getVersionStatus() ...');
      final status = await newVersion.getVersionStatus();
      debugPrint('[UpdateChecker] getVersionStatus() returned: $status');

      if (status == null) {
        debugPrint('[UpdateChecker] status == null -> no store info');
        if (forceShowForDebug) {
          debugPrint('[UpdateChecker] forceShowForDebug is true -> showing debug dialog');
          // 擬似ステータス情報でダイアログ表示（storeVersion を示すなど）
          await _ensureContextAndShowDialog(newVersion, prefs, fakeStoreVersion: 'dev-test');
        }
        return;
      }

      debugPrint('[UpdateChecker] canUpdate: ${status.canUpdate}');
      debugPrint('[UpdateChecker] localVersion: ${status.localVersion}');
      debugPrint('[UpdateChecker] storeVersion: ${status.storeVersion}');
      debugPrint('[UpdateChecker] appStoreLink: ${status.appStoreLink}');
      debugPrint('[UpdateChecker] releaseNotes: ${status.releaseNotes}');

      if (status.canUpdate || forceShowForDebug) {
        debugPrint('[UpdateChecker] update available or forced -> show dialog');
        await _ensureContextAndShowDialog(newVersion, prefs, status: status);
      } else {
        debugPrint('[UpdateChecker] no update available');
      }
    } catch (e, st) {
      debugPrint('[UpdateChecker] getVersionStatus error: $e');
      debugPrint(st.toString());
    } finally {
      debugPrint('[UpdateChecker] _checkAndShowDialog: exit');
    }
  }

  /// context が取れるまでリトライしてダイアログを表示する
  Future<void> _ensureContextAndShowDialog(
    NewVersionPlus newVersion,
    SharedPreferences prefs, {
    VersionStatus? status,
    String? fakeStoreVersion,
  }) async {
    int tries = 0;
    while (tries < _maxRetries) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        debugPrint('[UpdateChecker] context available after $tries tries');
        _showUpdateDialog(newVersion, prefs, context, status: status, fakeStoreVersion: fakeStoreVersion);
        return;
      }
      tries++;
      debugPrint('[UpdateChecker] waiting for context... try=$tries');
      await Future.delayed(_retryDelay);
    }
    debugPrint('[UpdateChecker] context still null after $_maxRetries tries; abort showing dialog');
  }

  void _showUpdateDialog(
    NewVersionPlus newVersion,
    SharedPreferences prefs,
    BuildContext context, {
    VersionStatus? status,
    String? fakeStoreVersion,
  }) {
    debugPrint('[UpdateChecker] _showUpdateDialog: showing AlertDialog');
    final storeInfo = status?.storeVersion ?? fakeStoreVersion;
    final releaseNotes = status?.releaseNotes ?? '';

    // ローカライゼーションを取得
    // unitGachaではAppLocalizationsは未実装のため、デフォルトのテキストを使用
    final isJapanese = AppLocale.isJapanese(context);
    final dialogTitle = isJapanese
        ? 'アップデートが利用可能です'
        : 'New Update Available';
    final dialogMessage = isJapanese
        ? 'アップデートしますか？'
        : 'Would you like to update?';
    final dialogLaterText = isJapanese
        ? '後で'
        : 'Later';
    final dialogUpdateText = isJapanese
        ? 'アップデート'
        : 'Update';
    final dialogReleaseNotesLabel = isJapanese
        ? 'リリースノート'
        : 'Release Notes';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dialogMessage),
            if (storeInfo != null) ...[
              const SizedBox(height: 8),
              Text(
                isJapanese ? 'ストアバージョン: $storeInfo' : 'Store version: $storeInfo',
                style: const TextStyle(fontSize: 12),
              ),
            ],
            if (releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '$dialogReleaseNotesLabel: $releaseNotes',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            child: Text(dialogLaterText),
            onPressed: () async {
              debugPrint('[UpdateChecker] user pressed: $dialogLaterText');
              await prefs.setInt("last_update_prompt_millis", DateTime.now().millisecondsSinceEpoch);
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            child: Text(dialogUpdateText),
            onPressed: () async {
              debugPrint('[UpdateChecker] user pressed: $dialogUpdateText');
              Navigator.of(ctx).pop();

              // ここが重要：launchAppStore は "ストアのリンク（URL）" を期待するので、
              // status?.appStoreLink を使い、なければフォールバックで URL を組み立てる。
              final String? statusLink = status?.appStoreLink;
              final String fallbackLink = PlatformInfo.isIOS
                  // iOS: App Store の id は通常数字（例: 123456789）。`iosId` が numeric でない場合は正しい URL にならない点に注意。
                  ? 'https://apps.apple.com/app/id$iosId'
                  // Android: package name を使って Play Store の URL を組み立てる
                  : 'https://play.google.com/store/apps/details?id=$androidId';

              final String appStoreLink = statusLink ?? fallbackLink;
              debugPrint('[UpdateChecker] launching app store with appStoreLink=$appStoreLink');

              try {
                await newVersion.launchAppStore(appStoreLink);
              } catch (e, st) {
                debugPrint('[UpdateChecker] launchAppStore error: $e');
                debugPrint(st.toString());
                // フォールバック：もし url_launcher を直接使う場合はここで開く（必要なら url_launcher を pubspec に追加）
                // import 'package:url_launcher/url_launcher_string.dart';
                // if (await canLaunchUrlString(appStoreLink)) await launchUrlString(appStoreLink);
              }
            },
          ),
        ],
      ),
    );
  }
}







