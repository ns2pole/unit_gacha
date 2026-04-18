// lib/services/firestore_learning_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore学習記録サービス
/// 学習記録の保存/取得、リアルタイム同期を提供
class FirestoreLearningService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ユーザーの学習記録コレクションへの参照を取得
  static CollectionReference _getUserLearningRecordsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('learning_records');
  }

  /// problemIdをFirestoreのドキュメントIDとして使用できるようにサニタイズ
  /// スラッシュをアンダースコアに置換（Firestoreのパス区切り文字として解釈されるのを防ぐ）
  static String _sanitizeProblemIdForDocId(String problemId) {
    return problemId.replaceAll('/', '_');
  }

  /// 学習記録を保存
  static Future<bool> saveLearningRecord({
    required String userId,
    required String problemId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final sanitizedDocId = _sanitizeProblemIdForDocId(problemId);
      final recordRef = _getUserLearningRecordsRef(userId).doc(sanitizedDocId);
      
      await recordRef.set({
        'problemId': problemId,
        'latestStatus': data['latestStatus'],
        'history': data['history'],
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error saving learning record to Firestore: $e');
      return false;
    }
  }

  /// 学習記録を取得
  static Future<Map<String, dynamic>?> getLearningRecord({
    required String userId,
    required String problemId,
  }) async {
    try {
      final sanitizedDocId = _sanitizeProblemIdForDocId(problemId);
      final recordDoc = await _getUserLearningRecordsRef(userId)
          .doc(sanitizedDocId)
          .get();

      if (!recordDoc.exists) {
        return null;
      }

      final data = recordDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        return null;
      }

      // Timestampを文字列に変換
      final lastUpdated = data['lastUpdated'];
      if (lastUpdated is Timestamp) {
        data['lastUpdated'] = lastUpdated.toDate().toIso8601String();
      }

      return data;
    } catch (e) {
      print('Error getting learning record from Firestore: $e');
      return null;
    }
  }

  /// 学習記録の履歴を取得
  static Future<List<Map<String, dynamic>>> getLearningHistory({
    required String userId,
    required String problemId,
  }) async {
    try {
      final record = await getLearningRecord(
        userId: userId,
        problemId: problemId,
      );

      if (record == null) {
        return [];
      }

      final history = record['history'] as List<dynamic>?;
      if (history == null) {
        return [];
      }

      return history
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (e) {
      print('Error getting learning history from Firestore: $e');
      return [];
    }
  }

  /// 学習記録の履歴を保存
  static Future<bool> saveLearningHistory({
    required String userId,
    required String problemId,
    required List<Map<String, dynamic>> history,
  }) async {
    try {
      // 最新ステータスを取得（noneでない最後のスロットを見つける）
      String latestStatus = 'none';
      for (var i = history.length - 1; i >= 0; i--) {
        final status = history[i]['status'] as String?;
        if (status != null && status != 'none') {
          latestStatus = status;
          break;
        }
      }

      final sanitizedDocId = _sanitizeProblemIdForDocId(problemId);
      final recordRef = _getUserLearningRecordsRef(userId).doc(sanitizedDocId);
      
      await recordRef.set({
        'problemId': problemId,
        'latestStatus': latestStatus,
        'history': history,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error saving learning history to Firestore: $e');
      return false;
    }
  }

  /// ユーザーの全学習記録を取得
  static Future<Map<String, Map<String, dynamic>>> getAllLearningRecords({
    required String userId,
  }) async {
    try {
      final snapshot = await _getUserLearningRecordsRef(userId).get();
      
      final Map<String, Map<String, dynamic>> records = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        
        // Timestampを文字列に変換
        final lastUpdated = data['lastUpdated'];
        if (lastUpdated is Timestamp) {
          data['lastUpdated'] = lastUpdated.toDate().toIso8601String();
        }
        
        // history配列内のtimeフィールドもTimestampから文字列に変換
        final history = data['history'] as List?;
        if (history != null) {
          final convertedHistory = history.map((item) {
            if (item is Map<String, dynamic>) {
              final convertedItem = Map<String, dynamic>.from(item);
              final time = convertedItem['time'];
              if (time is Timestamp) {
                convertedItem['time'] = time.toDate().toIso8601String();
              }
              return convertedItem;
            }
            return item;
          }).toList();
          data['history'] = convertedHistory;
        }
        
        // ドキュメントIDではなく、保存されている元のproblemIdを使用
        final originalProblemId = data['problemId'] as String? ?? doc.id;
        records[originalProblemId] = data;
      }
      
      return records;
    } catch (e) {
      print('Error getting all learning records from Firestore: $e');
      return {};
    }
  }

  /// 学習記録を削除
  static Future<bool> deleteLearningRecord({
    required String userId,
    required String problemId,
  }) async {
    try {
      final sanitizedDocId = _sanitizeProblemIdForDocId(problemId);
      await _getUserLearningRecordsRef(userId).doc(sanitizedDocId).delete();
      return true;
    } catch (e) {
      print('Error deleting learning record from Firestore: $e');
      return false;
    }
  }

  /// リアルタイムで学習記録を監視
  static Stream<DocumentSnapshot> watchLearningRecord({
    required String userId,
    required String problemId,
  }) {
    final sanitizedDocId = _sanitizeProblemIdForDocId(problemId);
    return _getUserLearningRecordsRef(userId)
        .doc(sanitizedDocId)
        .snapshots();
  }
}

