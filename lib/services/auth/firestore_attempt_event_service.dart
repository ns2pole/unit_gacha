import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;

enum AttemptEventUpsertErrorKind {
  permissionDenied,
  unauthenticated,
  network,
  unknown,
}

class AttemptEventUpsertResult {
  final bool ok;
  final AttemptEventUpsertErrorKind? errorKind;
  final String? errorCode;
  final String? message;

  const AttemptEventUpsertResult._({
    required this.ok,
    this.errorKind,
    this.errorCode,
    this.message,
  });

  const AttemptEventUpsertResult.ok() : this._(ok: true);

  const AttemptEventUpsertResult.err({
    required AttemptEventUpsertErrorKind kind,
    String? code,
    String? message,
  }) : this._(
          ok: false,
          errorKind: kind,
          errorCode: code,
          message: message,
        );
}

/// Firestore attempt event service (unit_gacha)
///
/// Path:
/// - users/{uid}/unit_gacha_attempt_events/{eventId}
class FirestoreAttemptEventService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _userAttemptEventsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('unit_gacha_attempt_events');
  }

  /// Create (idempotent) attempt event.
  ///
  /// - eventId: client-generated stable ID (prevents duplicates on retry)
  /// - weekly bucketing uses server commit time in Cloud Functions
  static Future<AttemptEventUpsertResult> upsertAttemptEvent({
    required String userId,
    required String eventId,
    required String problemId,
    required String status, // 'solved' | 'failed'
    required String clientTimeIso,
  }) async {
    try {
      final ref = _userAttemptEventsRef(userId).doc(eventId);

      // Defensive: avoid turning a retry into an "update" write.
      // (Cloud Functions leaderboard uses onCreate triggers.)
      final existing = await ref.get();
      if (existing.exists) {
        return const AttemptEventUpsertResult.ok();
      }

      await ref.set({
        'problemId': problemId,
        'status': status,
        'clientTime': clientTimeIso,
      }, SetOptions(merge: false));
      return const AttemptEventUpsertResult.ok();
    } catch (e) {
      // Note: caller retries via queue. We still want to classify the error so the UI can guide the user.
      if (e is FirebaseException) {
        final code = e.code;
        final kind = switch (code) {
          'permission-denied' => AttemptEventUpsertErrorKind.permissionDenied,
          'unauthenticated' => AttemptEventUpsertErrorKind.unauthenticated,
          'unavailable' || 'deadline-exceeded' => AttemptEventUpsertErrorKind.network,
          _ => AttemptEventUpsertErrorKind.unknown,
        };
        return AttemptEventUpsertResult.err(kind: kind, code: code, message: e.message);
      }

      final s = e.toString().toLowerCase();
      if (s.contains('permission-denied') || s.contains('permission denied')) {
        return const AttemptEventUpsertResult.err(kind: AttemptEventUpsertErrorKind.permissionDenied);
      }
      if (s.contains('unauthenticated')) {
        return const AttemptEventUpsertResult.err(kind: AttemptEventUpsertErrorKind.unauthenticated);
      }
      if (s.contains('unavailable') || s.contains('network')) {
        return const AttemptEventUpsertResult.err(kind: AttemptEventUpsertErrorKind.network);
      }

      return AttemptEventUpsertResult.err(kind: AttemptEventUpsertErrorKind.unknown, message: e.toString());
    }
  }
}



