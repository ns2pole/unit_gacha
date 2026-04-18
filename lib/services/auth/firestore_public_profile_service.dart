import 'package:cloud_firestore/cloud_firestore.dart';

class UnitGachaPublicProfile {
  final bool participating;
  final String? nickname;
  final Timestamp? initRequestedAt;

  const UnitGachaPublicProfile({
    required this.participating,
    required this.nickname,
    required this.initRequestedAt,
  });

  static UnitGachaPublicProfile fromMap(Map<String, dynamic>? data) {
    final participating = data?['participating'] == true;
    final nicknameAny = data?['nickname'];
    final nickname = nicknameAny is String && nicknameAny.trim().isNotEmpty ? nicknameAny.trim() : null;
    final initRequestedAt = data?['initRequestedAt'];
    return UnitGachaPublicProfile(
      participating: participating,
      nickname: nickname,
      initRequestedAt: initRequestedAt is Timestamp ? initRequestedAt : null,
    );
  }
}

/// Public profile for unit_gacha ranking.
///
/// Path:
/// - users/{uid}/public_profile/unit_gacha
class FirestorePublicProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Set<String> _autoRepairedUnitGachaParticipationUserIds = <String>{};

  static DocumentReference<Map<String, dynamic>> _doc(String userId) {
    return _firestore.collection('users').doc(userId).collection('public_profile').doc('unit_gacha');
  }

  static DocumentReference<Map<String, dynamic>> _overallLeaderboardDoc(String userId) {
    return _firestore
        .collection('leaderboards')
        .doc('unit_gacha_overall')
        .collection('users')
        .doc(userId);
  }

  static Future<UnitGachaPublicProfile> getUnitGachaProfile({
    required String userId,
  }) async {
    final snap = await _doc(userId).get();
    return UnitGachaPublicProfile.fromMap(snap.data());
  }

  static Stream<UnitGachaPublicProfile> watchUnitGachaProfile({
    required String userId,
  }) {
    return _doc(userId).snapshots().map((snap) => UnitGachaPublicProfile.fromMap(snap.data()));
  }

  /// Auto-repair inconsistent participation state for legacy users.
  ///
  /// Background:
  /// - Cloud Functions score updates require `public_profile/unit_gacha.participating == true`.
  /// - Some legacy users can have an overall leaderboard doc but missing/false participation.
  ///   In that case, new attempt events are ignored and score never increases until the user
  ///   manually toggles OFF→ON.
  ///
  /// This method silently restores participation when we can prove the user was participating
  /// before (overall leaderboard doc exists).
  ///
  /// Returns true if a repair write was performed.
  static Future<bool> autoRepairUnitGachaParticipationIfNeeded({
    required String userId,
  }) async {
    if (_autoRepairedUnitGachaParticipationUserIds.contains(userId)) return false;
    _autoRepairedUnitGachaParticipationUserIds.add(userId);

    try {
      final profileSnap = await _doc(userId).get();
      final participating = profileSnap.data()?['participating'] == true;
      if (participating) return false;

      final overallSnap = await _overallLeaderboardDoc(userId).get();
      if (!overallSnap.exists) return false;

      await setUnitGachaParticipating(userId: userId, participating: true);
      return true;
    } catch (_) {
      // Best-effort: do not block UI.
      return false;
    }
  }

  /// Update participating flag and request overall initialization on server.
  ///
  /// Cloud Functions can watch `initRequestedAt` and (re)build overall leaderboard.
  static Future<void> setUnitGachaParticipating({
    required String userId,
    required bool participating,
  }) async {
    await _doc(userId).set({
      'participating': participating,
      'updatedAt': FieldValue.serverTimestamp(),
      if (participating) 'initRequestedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> setUnitGachaNickname({
    required String userId,
    required String? nickname,
  }) async {
    final trimmed = nickname?.trim();
    await _doc(userId).set({
      'nickname': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}



