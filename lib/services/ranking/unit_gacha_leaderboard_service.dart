import 'package:cloud_firestore/cloud_firestore.dart';

class UnitGachaLeaderboardRow {
  final String userId;
  final int score;
  final int? solved;
  final int? failed;
  final String? nickname;

  const UnitGachaLeaderboardRow({
    required this.userId,
    required this.score,
    this.solved,
    this.failed,
    this.nickname,
  });
}

class UnitGachaLeaderboardSnapshot {
  final int? myScore;
  final int? myRank;
  final int? totalUsers;
  final List<UnitGachaLeaderboardRow> top;

  const UnitGachaLeaderboardSnapshot({
    required this.myScore,
    required this.myRank,
    required this.totalUsers,
    required this.top,
  });
}

class UnitGachaLeaderboardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _overallUsersRef() {
    return _firestore.collection('leaderboards').doc('unit_gacha_overall').collection('users');
  }

  /// Weekly leaderboard users collection.
  ///
  /// Path:
  /// - leaderboards/unit_gacha_weekly/weeks/{weekKey}/users/{uid}
  static CollectionReference<Map<String, dynamic>> _weeklyUsersRef(String weekKey) {
    return _firestore
        .collection('leaderboards')
        .doc('unit_gacha_weekly')
        .collection('weeks')
        .doc(weekKey)
        .collection('users');
  }

  static DocumentReference<Map<String, dynamic>> _overallUserDoc(String userId) {
    return _overallUsersRef().doc(userId);
  }

  static DocumentReference<Map<String, dynamic>> _weeklyUserDoc(String weekKey, String userId) {
    return _weeklyUsersRef(weekKey).doc(userId);
  }

  static Future<UnitGachaLeaderboardSnapshot> fetchOverall({
    required String myUserId,
    int topLimit = 10,
  }) async {
    final base = _overallUsersRef();

    final topSnap = await base.orderBy('score', descending: true).limit(topLimit).get();
    final top = topSnap.docs.map((d) {
      final data = d.data();
      final score = (data['score'] as num?)?.toInt() ?? 0;
      final nicknameAny = data['nickname'];
      final nickname = nicknameAny is String && nicknameAny.trim().isNotEmpty ? nicknameAny.trim() : null;
      return UnitGachaLeaderboardRow(userId: d.id, score: score, nickname: nickname);
    }).toList();

    final myDoc = await _overallUserDoc(myUserId).get();
    if (!myDoc.exists) {
      final totalAgg = await base.count().get();
      return UnitGachaLeaderboardSnapshot(
        myScore: null,
        myRank: null,
        totalUsers: totalAgg.count,
        top: top,
      );
    }

    final myScore = ((myDoc.data()?['score'] as num?)?.toInt()) ?? 0;
    final higherAgg = await base.where('score', isGreaterThan: myScore).count().get();
    final totalAgg = await base.count().get();
    final myRank = higherAgg.count != null ? higherAgg.count! + 1 : null;

    return UnitGachaLeaderboardSnapshot(
      myScore: myScore,
      myRank: myRank,
      totalUsers: totalAgg.count,
      top: top,
    );
  }

  static Future<UnitGachaLeaderboardSnapshot> fetchWeekly({
    required String weekKey,
    required String myUserId,
    int topLimit = 10,
  }) async {
    final base = _weeklyUsersRef(weekKey);

    final topSnap = await base.orderBy('score', descending: true).limit(topLimit).get();
    final top = topSnap.docs.map((d) {
      final data = d.data();
      final score = (data['score'] as num?)?.toInt() ?? 0;
      final solved = (data['solved'] as num?)?.toInt();
      final failed = (data['failed'] as num?)?.toInt();
      final nicknameAny = data['nickname'];
      final nickname = nicknameAny is String && nicknameAny.trim().isNotEmpty ? nicknameAny.trim() : null;
      return UnitGachaLeaderboardRow(
        userId: d.id,
        score: score,
        solved: solved,
        failed: failed,
        nickname: nickname,
      );
    }).toList();

    final myDoc = await _weeklyUserDoc(weekKey, myUserId).get();
    if (!myDoc.exists) {
      final totalAgg = await base.count().get();
      return UnitGachaLeaderboardSnapshot(
        myScore: null,
        myRank: null,
        totalUsers: totalAgg.count,
        top: top,
      );
    }

    final myScore = ((myDoc.data()?['score'] as num?)?.toInt()) ?? 0;
    final higherAgg = await base.where('score', isGreaterThan: myScore).count().get();
    final totalAgg = await base.count().get();
    final myRank = higherAgg.count != null ? higherAgg.count! + 1 : null;

    return UnitGachaLeaderboardSnapshot(
      myScore: myScore,
      myRank: myRank,
      totalUsers: totalAgg.count,
      top: top,
    );
  }
}



