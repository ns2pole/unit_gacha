import 'dart:async';

import 'package:flutter/material.dart';

import '../../localization/app_localizations.dart';
import '../../services/auth/firebase_auth_service.dart';
import '../../services/auth/firestore_public_profile_service.dart';
import '../../services/problems/simple_data_manager.dart';

/// Ranking settings panel (participation toggle + nickname) for Unit Gacha.
///
/// - Shows a "login required" hint when user is not authenticated.
/// - When participating is enabled, attempts to sync queued attempt events to Firestore
///   in the background (best-effort).
class UnitGachaRankingSettingsPanel extends StatefulWidget {
  final bool showWhenLoggedOut;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onRankingChanged;

  const UnitGachaRankingSettingsPanel({
    super.key,
    this.showWhenLoggedOut = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.onRankingChanged,
  });

  @override
  State<UnitGachaRankingSettingsPanel> createState() => _UnitGachaRankingSettingsPanelState();
}

class _UnitGachaRankingSettingsPanelState extends State<UnitGachaRankingSettingsPanel> {
  bool _busy = false;
  final TextEditingController _nicknameController = TextEditingController();
  bool _didInitNicknameController = false;
  int _participationOpId = 0;

  bool get _isLoggedIn => FirebaseAuthService.isAuthenticated;
  String? get _userId => FirebaseAuthService.userId;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _setParticipating(bool value) async {
    final uid = _userId;
    if (uid == null) return;

    final opId = ++_participationOpId;
    setState(() => _busy = true);
    try {
      await FirestorePublicProfileService.setUnitGachaParticipating(
        userId: uid,
        participating: value,
      );
      widget.onRankingChanged?.call();

      if (value) {
        // Best-effort background sync for ranking events
        unawaited(() async {
          try {
            await SimpleDataManager.syncUnitGachaAttemptEventsToFirestore();
          } catch (_) {
            // keep participation state; next sync will catch up
          }
          if (!mounted) return;
          if (opId != _participationOpId) return;
          // poke initRequestedAt again after sync (best-effort)
          try {
            await FirestorePublicProfileService.setUnitGachaParticipating(
              userId: uid,
              participating: true,
            );
          } catch (_) {}
          widget.onRankingChanged?.call();
        }());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveNickname() async {
    final uid = _userId;
    if (uid == null) return;
    final raw = _nicknameController.text.trim();
    final nickname = raw.isEmpty ? null : raw;
    setState(() => _busy = true);
    try {
      await FirestorePublicProfileService.setUnitGachaNickname(userId: uid, nickname: nickname);
      widget.onRankingChanged?.call();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _container({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final uid = _userId!;
    return StreamBuilder<UnitGachaPublicProfile>(
      stream: FirestorePublicProfileService.watchUnitGachaProfile(userId: uid),
      builder: (context, snapshot) {
        final profile = snapshot.data ??
            const UnitGachaPublicProfile(participating: false, nickname: null, initRequestedAt: null);

        if (!_didInitNicknameController) {
          _nicknameController.text = profile.nickname ?? '';
          _didInitNicknameController = true;
        }

        return _container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.rankingParticipation,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Switch(
                    value: profile.participating,
                    onChanged: _busy ? null : (v) => _setParticipating(v),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nicknameController,
                      enabled: !_busy && profile.participating,
                      maxLength: 12,
                      decoration: InputDecoration(
                        isDense: true,
                        counterText: '',
                        labelText: l10n.nicknameOptional,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: (!_busy && profile.participating) ? _saveNickname : null,
                    child: Text(l10n.save),
                  ),
                ],
              ),
              if (!profile.participating)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l10n.rankingParticipationNote,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    textAlign: TextAlign.left,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}


