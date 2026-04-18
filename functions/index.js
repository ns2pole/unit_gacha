const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const MAX_STREAK = 10;
// NOTE:
// Do NOT hardcode the service account email.
// In non-`unitgacha` Firebase projects this breaks triggers (service account not found).
// Default runtime service account is sufficient for Admin SDK access.

function pad2(n) {
  return String(n).padStart(2, "0");
}

// Weekly is defined by JST (Mon-Sun) using server commit time.
function weekKeyFromServerDate(serverDate) {
  const JST_OFFSET_MS = 9 * 60 * 60 * 1000;
  const jst = new Date(serverDate.getTime() + JST_OFFSET_MS);

  // Treat UTC components as JST calendar parts (because we shifted by +9h).
  const y = jst.getUTCFullYear();
  const m = jst.getUTCMonth();
  const d = jst.getUTCDate();

  // 0=Sun..6=Sat on shifted date (in UTC component space).
  const dow = jst.getUTCDay();
  const daysFromMonday = dow === 0 ? 6 : dow - 1;
  const monday = new Date(Date.UTC(y, m, d - daysFromMonday));

  return `${monday.getUTCFullYear()}-${pad2(monday.getUTCMonth() + 1)}-${pad2(monday.getUTCDate())}`;
}

function sanitizeProblemId(problemId) {
  return String(problemId).replaceAll("/", "_");
}

async function getUnitGachaProfile(uid) {
  const ref = db.collection("users").doc(uid).collection("public_profile").doc("unit_gacha");
  const snap = await ref.get();
  const data = snap.exists ? snap.data() : null;
  return {
    participating: data && data.participating === true,
    nickname: data && typeof data.nickname === "string" ? data.nickname : null,
    initRequestedAt: data && data.initRequestedAt ? data.initRequestedAt : null,
  };
}

function computeStreakFromHistory(history) {
  if (!Array.isArray(history)) return 0;
  const calcOnly = history.filter((r) => r && r.byCalculator === true);
  if (calcOnly.length === 0) return 0;

  // Sort by time (string ISO or Firestore Timestamp) ascending
  calcOnly.sort((a, b) => {
    const ta = a.time;
    const tb = b.time;
    const da = ta && typeof ta.toDate === "function" ? ta.toDate() : new Date(String(ta || ""));
    const dbb = tb && typeof tb.toDate === "function" ? tb.toDate() : new Date(String(tb || ""));
    return da.getTime() - dbb.getTime();
  });

  // Newest first
  const newestFirst = calcOnly.slice().reverse();
  let streak = 0;
  for (const r of newestFirst) {
    if (!r || r.status !== "solved") break;
    streak += 1;
    if (streak >= MAX_STREAK) return MAX_STREAK;
  }
  return streak;
}

function isoLocalStringFromUtcDateParts(y, m1, d, hh, mm, ss, ms) {
  // Build an ISO-like string without timezone suffix:
  // YYYY-MM-DDTHH:mm:ss.sss
  // This matches Dart's `DateTime.now().toIso8601String()` format used in `clientTime`.
  return `${y}-${pad2(m1)}-${pad2(d)}T${pad2(hh)}:${pad2(mm)}:${pad2(ss)}.${String(ms).padStart(3, "0")}`;
}

function weekRangeIsoFromServerDate(serverDate) {
  // Compute [startIso, endIso) for the current JST week (Mon 00:00 .. next Mon 00:00),
  // and return { weekKey, startIso, endIso }.
  const JST_OFFSET_MS = 9 * 60 * 60 * 1000;
  const jst = new Date(serverDate.getTime() + JST_OFFSET_MS);

  const y = jst.getUTCFullYear();
  const m = jst.getUTCMonth(); // 0-based
  const d = jst.getUTCDate();

  const dow = jst.getUTCDay(); // 0=Sun..6=Sat in shifted space
  const daysFromMonday = dow === 0 ? 6 : dow - 1;
  const monday = new Date(Date.UTC(y, m, d - daysFromMonday));
  const nextMonday = new Date(Date.UTC(y, m, d - daysFromMonday + 7));

  const weekKey = `${monday.getUTCFullYear()}-${pad2(monday.getUTCMonth() + 1)}-${pad2(monday.getUTCDate())}`;
  const startIso = isoLocalStringFromUtcDateParts(
    monday.getUTCFullYear(),
    monday.getUTCMonth() + 1,
    monday.getUTCDate(),
    0,
    0,
    0,
    0
  );
  const endIso = isoLocalStringFromUtcDateParts(
    nextMonday.getUTCFullYear(),
    nextMonday.getUTCMonth() + 1,
    nextMonday.getUTCDate(),
    0,
    0,
    0,
    0
  );

  return { weekKey, startIso, endIso };
}

function summarizeSolvedFailedFromHistory(history) {
  if (!Array.isArray(history)) return { solved: 0, failed: 0, everSolved: false };
  let solved = 0;
  let failed = 0;
  let everSolved = false;
  for (const r of history) {
    if (!r || r.byCalculator !== true) continue;
    if (r.status === "solved") {
      solved += 1;
      everSolved = true;
    } else if (r.status === "failed") {
      failed += 1;
    }
  }
  return { solved, failed, everSolved };
}

exports.onUnitGachaAttemptEventCreate = functions
  .firestore
  .document("users/{uid}/unit_gacha_attempt_events/{eventId}")
  .onCreate(async (snap, context) => {
    const uid = context.params.uid;
    const data = snap.data() || {};

    const status = data.status;
    const problemId = data.problemId;
    if ((status !== "solved" && status !== "failed") || !problemId) {
      functions.logger.warn("unit_gacha_attempt_event_invalid", { uid, status, problemId });
      return null;
    }

    const profile = await getUnitGachaProfile(uid);
    if (!profile.participating) {
      // This is the common "score won't move unless user toggles participation" symptom.
      // We log it so we can confirm whether attempt events are being created & whether
      // they are being ignored due to participation mismatch.
      functions.logger.warn("unit_gacha_attempt_event_ignored_not_participating", {
        uid,
        status,
        problemId,
        eventId: context.params.eventId,
      });
      // Weekly should not count when user isn't participating.
      // Overall leaderboard will be (re)initialized when participating becomes true.
      return null;
    }

    // Use commit time for weekly bucketing to prevent retroactive changes.
    const serverDate = new Date(context.timestamp);
    const weekKey = weekKeyFromServerDate(serverDate);

    const weeklyRef = db
      .collection("leaderboards")
      .doc("unit_gacha_weekly")
      .collection("weeks")
      .doc(weekKey)
      .collection("users")
      .doc(uid);

    const overallRef = db.collection("leaderboards").doc("unit_gacha_overall").collection("users").doc(uid);
    const stateRef = db
      .collection("users")
      .doc(uid)
      .collection("ranking_state")
      .doc("unit_gacha")
      .collection("problems")
      .doc(sanitizeProblemId(problemId));

    const solvedInc = status === "solved" ? 1 : 0;
    const failedInc = status === "failed" ? 1 : 0;
    const scoreInc = solvedInc - failedInc;

    // Use atomic create() to decide uniqueSolvedDelta without any reads.
    // This avoids Firestore transaction read/write ordering issues and guarantees uniqueSolved increments once.
    const weeklyUpdate = {
      score: admin.firestore.FieldValue.increment(scoreInc),
      solved: admin.firestore.FieldValue.increment(solvedInc),
      failed: admin.firestore.FieldValue.increment(failedInc),
      nickname: profile.nickname || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (status === "solved") {
      // First try: treat as first-ever solve for this problem (uniqueSolvedDelta=1) via create().
      const batch = db.batch();
      batch.create(stateRef, {
        everSolved: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      batch.set(weeklyRef, weeklyUpdate, { merge: true });
      batch.set(
        overallRef,
        {
          score: admin.firestore.FieldValue.increment(scoreInc + 1),
          solved: admin.firestore.FieldValue.increment(solvedInc),
          failed: admin.firestore.FieldValue.increment(failedInc),
          uniqueSolved: admin.firestore.FieldValue.increment(1),
          nickname: profile.nickname || null,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      try {
        await batch.commit();
      } catch (e) {
        // If the state doc already exists, retry without uniqueSolved bonus.
        const msg = String(e && e.message ? e.message : e).toLowerCase();
        const alreadyExists =
          msg.includes("already exists") ||
          msg.includes("already-exists") ||
          msg.includes("6 already exists");
        if (!alreadyExists) {
          throw e;
        }

        const batch2 = db.batch();
        batch2.set(
          stateRef,
          {
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
        batch2.set(weeklyRef, weeklyUpdate, { merge: true });
        batch2.set(
          overallRef,
          {
            score: admin.firestore.FieldValue.increment(scoreInc),
            solved: admin.firestore.FieldValue.increment(solvedInc),
            failed: admin.firestore.FieldValue.increment(failedInc),
            uniqueSolved: admin.firestore.FieldValue.increment(0),
            nickname: profile.nickname || null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
        await batch2.commit();
      }
    } else {
      // failed
      const batch = db.batch();
      batch.set(
        stateRef,
        {
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      batch.set(weeklyRef, weeklyUpdate, { merge: true });
      batch.set(
        overallRef,
        {
          score: admin.firestore.FieldValue.increment(scoreInc),
          solved: admin.firestore.FieldValue.increment(solvedInc),
          failed: admin.firestore.FieldValue.increment(failedInc),
          uniqueSolved: admin.firestore.FieldValue.increment(0),
          nickname: profile.nickname || null,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      await batch.commit();
    }

    functions.logger.info("unit_gacha_attempt_event_processed", {
      uid,
      status,
      problemId,
      weekKey,
      eventId: context.params.eventId,
      scoreInc,
    });
    return null;
  });

exports.onUnitGachaProfileWrite = functions
  .firestore
  .document("users/{uid}/public_profile/unit_gacha")
  .onWrite(async (change, context) => {
    const uid = context.params.uid;
    const after = change.after.exists ? change.after.data() : null;
    const before = change.before.exists ? change.before.data() : null;

    const participating = after && after.participating === true;

    const overallRef = db.collection("leaderboards").doc("unit_gacha_overall").collection("users").doc(uid);
    const statsRef = db.collection("users").doc(uid).collection("stats").doc("unit_gacha");

    if (!participating) {
      // Opt-out: remove from overall leaderboard.
      // Weekly is defined as "participating at the time of attempts", so we keep past weeks intact.
      await overallRef.delete().catch(() => null);
      return null;
    }

    // Ensure the overall leaderboard doc exists promptly once participating is enabled.
    // Without this, the app can show "no rank" even after opting in if init takes time / fails.
    // We do NOT overwrite an existing score.
    try {
      const overallSnap = await overallRef.get();
      if (!overallSnap.exists) {
        await overallRef.set(
          {
            score: 0,
            solved: 0,
            failed: 0,
            uniqueSolved: 0,
            nickname: after && typeof after.nickname === "string" ? after.nickname : null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      }
    } catch (_) {
      // Non-fatal: ranking init can still proceed.
    }

    // If participating became true, backfill the current week from attempt events so this week's
    // pre-opt-in attempts are reflected.
    const beforeParticipating = before && before.participating === true;
    if (!beforeParticipating) {
      try {
        const serverDate = new Date(context.timestamp);
        const { weekKey, startIso, endIso } = weekRangeIsoFromServerDate(serverDate);
        const weeklyRef = db
          .collection("leaderboards")
          .doc("unit_gacha_weekly")
          .collection("weeks")
          .doc(weekKey)
          .collection("users")
          .doc(uid);

        const attemptsSnap = await db
          .collection("users")
          .doc(uid)
          .collection("unit_gacha_attempt_events")
          .where("clientTime", ">=", startIso)
          .where("clientTime", "<", endIso)
          .get();

        let solved = 0;
        let failed = 0;
        attemptsSnap.forEach((d) => {
          const v = d.data() || {};
          if (v.status === "solved") solved += 1;
          else if (v.status === "failed") failed += 1;
        });

        await weeklyRef.set(
          {
            score: solved - failed,
            solved,
            failed,
            nickname: after && typeof after.nickname === "string" ? after.nickname : null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            backfilledAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      } catch (_) {
        // Non-fatal: weekly backfill failure should not block opt-in.
      }
    }

    // Nickname change should propagate to current overall leaderboard doc even without init.
    if (after && Object.prototype.hasOwnProperty.call(after, "nickname")) {
      await overallRef.set(
        {
          nickname: typeof after.nickname === "string" ? after.nickname : null,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    const initRequestedAt = after && after.initRequestedAt ? after.initRequestedAt : null;
    if (!initRequestedAt) return null;

    // If initRequestedAt didn't change, skip.
    if (before && before.initRequestedAt && initRequestedAt.isEqual && initRequestedAt.isEqual(before.initRequestedAt)) {
      return null;
    }

    // Recompute overall score from learning_records (byCalculator=true):
    // overallScore = solved - failed + uniqueSolvedProblems
    const lrSnap = await db.collection("users").doc(uid).collection("learning_records").get();

    let totalSolved = 0;
    let totalFailed = 0;
    let uniqueSolved = 0;
    const perProblem = []; // {problemIdSanitized, everSolved}

    lrSnap.forEach((doc) => {
      const d = doc.data() || {};
      const history = d.history;
      const s = summarizeSolvedFailedFromHistory(history);
      totalSolved += s.solved;
      totalFailed += s.failed;
      if (s.everSolved) uniqueSolved += 1;
      perProblem.push({ problemIdSanitized: sanitizeProblemId(d.problemId || doc.id), everSolved: s.everSolved });
    });

    // Write overall leaderboard score
    const totalScore = totalSolved - totalFailed + uniqueSolved;
    await overallRef.set(
      {
        score: totalScore,
        solved: totalSolved,
        failed: totalFailed,
        uniqueSolved,
        nickname: (after && typeof after.nickname === "string" ? after.nickname : null) || null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // Save stats (useful for debugging / future threshold rankings)
    await statsRef.set(
      {
        totalScore,
        totalSolved,
        totalFailed,
        uniqueSolved,
        lastInitAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // Seed per-problem state so incremental updates become correct immediately.
    // (Only for problems that exist in learning_records; others are implicitly false.)
    const stateCol = db.collection("users").doc(uid).collection("ranking_state").doc("unit_gacha").collection("problems");
    const BATCH_LIMIT = 450;
    for (let i = 0; i < perProblem.length; i += BATCH_LIMIT) {
      const batch = db.batch();
      for (const s of perProblem.slice(i, i + BATCH_LIMIT)) {
        batch.set(
          stateCol.doc(s.problemIdSanitized),
          {
            everSolved: s.everSolved === true,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      }
      await batch.commit();
    }

    return null;
  });



