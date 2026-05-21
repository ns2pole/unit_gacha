const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const MAX_STREAK = 10;

function pad2(n) {
  return String(n).padStart(2, "0");
}

// Weekly is defined by JST (Mon-Sun).
function weekKeyFromServerDate(serverDate) {
  const JST_OFFSET_MS = 9 * 60 * 60 * 1000;
  const jst = new Date(serverDate.getTime() + JST_OFFSET_MS);

  const y = jst.getUTCFullYear();
  const m = jst.getUTCMonth();
  const d = jst.getUTCDate();

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

function isoLocalStringFromUtcDateParts(y, m1, d, hh, mm, ss, ms) {
  return `${y}-${pad2(m1)}-${pad2(d)}T${pad2(hh)}:${pad2(mm)}:${pad2(ss)}.${String(ms).padStart(3, "0")}`;
}

function weekRangeIsoFromServerDate(serverDate) {
  const JST_OFFSET_MS = 9 * 60 * 60 * 1000;
  const jst = new Date(serverDate.getTime() + JST_OFFSET_MS);

  const y = jst.getUTCFullYear();
  const m = jst.getUTCMonth();
  const d = jst.getUTCDate();

  const dow = jst.getUTCDay();
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

function historyEntryKey(r) {
  const t = r.updatedAt || r.time;
  return `${String(t || "")}|${r.status}|calc`;
}

function dateFromHistoryEntry(entry) {
  const t = entry.time || entry.updatedAt;
  if (!t) return null;
  if (typeof t.toDate === "function") return t.toDate();
  const d = new Date(String(t));
  return Number.isNaN(d.getTime()) ? null : d;
}

function findNewRankingHistoryEntries(beforeHistory, afterHistory) {
  const before = Array.isArray(beforeHistory) ? beforeHistory : [];
  const after = Array.isArray(afterHistory) ? afterHistory : [];
  const beforeKeys = new Set(
    before
      .filter((r) => r && r.byCalculator === true)
      .map(historyEntryKey)
  );

  const out = [];
  for (const r of after) {
    if (!r || r.byCalculator !== true) continue;
    if (r.status !== "solved" && r.status !== "failed") continue;
    const k = historyEntryKey(r);
    if (beforeKeys.has(k)) continue;
    beforeKeys.add(k);
    out.push(r);
  }
  return out;
}

function countWeeklySolvedFailedFromLearningRecords(lrSnap, startIso, endIso) {
  let solved = 0;
  let failed = 0;
  lrSnap.forEach((doc) => {
    const history = (doc.data() || {}).history;
    if (!Array.isArray(history)) return;
    for (const r of history) {
      if (!r || r.byCalculator !== true) continue;
      const t = r.time || r.updatedAt;
      if (!t) continue;
      const timeStr =
        typeof t.toDate === "function" ? t.toDate().toISOString() : String(t);
      if (timeStr < startIso || timeStr >= endIso) continue;
      if (r.status === "solved") solved += 1;
      else if (r.status === "failed") failed += 1;
    }
  });
  return { solved, failed };
}

async function applyRankingIncrement({
  uid,
  problemId,
  status,
  weekKey,
  nickname,
}) {
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

  const weeklyUpdate = {
    score: admin.firestore.FieldValue.increment(scoreInc),
    solved: admin.firestore.FieldValue.increment(solvedInc),
    failed: admin.firestore.FieldValue.increment(failedInc),
    nickname: nickname || null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (status === "solved") {
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
        nickname: nickname || null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    try {
      await batch.commit();
    } catch (e) {
      const msg = String(e && e.message ? e.message : e).toLowerCase();
      const alreadyExists =
        msg.includes("already exists") ||
        msg.includes("already-exists") ||
        msg.includes("6 already exists");
      if (!alreadyExists) throw e;

      const batch2 = db.batch();
      batch2.set(
        stateRef,
        { updatedAt: admin.firestore.FieldValue.serverTimestamp() },
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
          nickname: nickname || null,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      await batch2.commit();
    }
  } else {
    const batch = db.batch();
    batch.set(
      stateRef,
      { updatedAt: admin.firestore.FieldValue.serverTimestamp() },
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
        nickname: nickname || null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    await batch.commit();
  }
}

/// 学習履歴（byCalculator=true）の追加をランキングへ反映する
exports.onUnitGachaLearningRecordWrite = functions
  .firestore
  .document("users/{uid}/learning_records/{docId}")
  .onWrite(async (change, context) => {
    if (!change.after.exists) return null;

    const uid = context.params.uid;
    const after = change.after.data() || {};
    const problemId = after.problemId || context.params.docId;
    const beforeHistory = change.before.exists ? change.before.data().history : [];
    const afterHistory = after.history;

    const newEntries = findNewRankingHistoryEntries(beforeHistory, afterHistory);
    if (newEntries.length === 0) return null;

    const profile = await getUnitGachaProfile(uid);
    if (!profile.participating) {
      functions.logger.warn("learning_record_ranking_ignored_not_participating", {
        uid,
        problemId,
        newCount: newEntries.length,
      });
      return null;
    }

    const fallbackDate = new Date(context.timestamp);
    for (const entry of newEntries) {
      const entryDate = dateFromHistoryEntry(entry) || fallbackDate;
      const weekKey = weekKeyFromServerDate(entryDate);
      await applyRankingIncrement({
        uid,
        problemId,
        status: entry.status,
        weekKey,
        nickname: profile.nickname,
      });
    }

    functions.logger.info("learning_record_ranking_processed", {
      uid,
      problemId,
      newCount: newEntries.length,
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
      await overallRef.delete().catch(() => null);
      return null;
    }

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
    } catch (_) {}

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

        const lrSnap = await db.collection("users").doc(uid).collection("learning_records").get();
        const { solved, failed } = countWeeklySolvedFailedFromLearningRecords(lrSnap, startIso, endIso);

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
      } catch (_) {}
    }

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

    if (before && before.initRequestedAt && initRequestedAt.isEqual && initRequestedAt.isEqual(before.initRequestedAt)) {
      return null;
    }

    const lrSnap = await db.collection("users").doc(uid).collection("learning_records").get();

    let totalSolved = 0;
    let totalFailed = 0;
    let uniqueSolved = 0;
    const perProblem = [];

    lrSnap.forEach((doc) => {
      const d = doc.data() || {};
      const history = d.history;
      const s = summarizeSolvedFailedFromHistory(history);
      totalSolved += s.solved;
      totalFailed += s.failed;
      if (s.everSolved) uniqueSolved += 1;
      perProblem.push({
        problemIdSanitized: sanitizeProblemId(d.problemId || doc.id),
        everSolved: s.everSolved,
      });
    });

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
