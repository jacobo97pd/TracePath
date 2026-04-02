const admin = require("firebase-admin");
const { getFirestore } = require("firebase-admin/firestore");
const { Resend } = require("resend");
const { defineSecret } = require("firebase-functions/params");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2/options");

admin.initializeApp();

setGlobalOptions({
  region: "europe-west1",
  memory: "256MiB",
  timeoutSeconds: 30,
});

const RESEND_API_KEY = defineSecret("RESEND_API_KEY");
const FIRESTORE_DATABASE_ID = "tracepath-database";
const SUPPORT_EMAIL = "soporte.tracepath@gmail.com";
// Ajusta este remitente al dominio verificado final de Resend.
const RESEND_FROM = "TracePath Reports <onboarding@resend.dev>";

function normalizeString(value) {
  if (typeof value !== "string") return "";
  return value.trim();
}

function buildReportId(uid, levelId) {
  const safeLevel = levelId.replace(/[^\w.-]/g, "_");
  return `${uid}_${safeLevel}`;
}

exports.reportLevelAndUnlockNext = onCall(
  { secrets: [RESEND_API_KEY] },
  async (request) => {
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError("unauthenticated", "Authentication is required.");
    }

    const uid = request.auth.uid;
    const data = request.data || {};
    const levelId = normalizeString(data.levelId);
    const nextLevelId = normalizeString(data.nextLevelId);
    const reason =
      normalizeString(data.reason) || "Nivel reportado como imposible";
    const appVersion = normalizeString(data.appVersion) || "unknown";
    const platform = normalizeString(data.platform) || "unknown";
    const nextLevelIndexRaw = Number(data.nextLevelIndex);
    const nextLevelIndex =
      Number.isFinite(nextLevelIndexRaw) && nextLevelIndexRaw > 0
        ? Math.floor(nextLevelIndexRaw)
        : null;

    if (!levelId) {
      throw new HttpsError(
        "invalid-argument",
        "Missing required field: levelId",
      );
    }
    if (!nextLevelId) {
      throw new HttpsError(
        "invalid-argument",
        "Missing required field: nextLevelId",
      );
    }

    let db;
    try {
      db = getFirestore(admin.app(), FIRESTORE_DATABASE_ID);
    } catch (e) {
      console.error(
        "[report-level] could not open named firestore db, using default",
        e,
      );
      db = getFirestore();
    }

    const userRef = db.collection("users").doc(uid);
    const reportRef = db.collection("level_reports").doc(buildReportId(uid, levelId));
    const unlockRef = userRef.collection("unlocked_levels").doc(nextLevelId);
    const progressRef = userRef.collection("progress").doc("campaign");

    let reportCreated = false;
    await db.runTransaction(async (tx) => {
      const reportSnap = await tx.get(reportRef);
      const userSnap = await tx.get(userRef);
      const userData = userSnap.data() || {};

      const reportedIds = Array.isArray(userData.reportedLevelIds)
        ? userData.reportedLevelIds
        : [];
      const currentHighest = Number(userData.highestLevelReached || 1);

      if (!reportSnap.exists) {
        reportCreated = true;
        tx.set(reportRef, {
          uid,
          levelId,
          nextLevelId,
          reason,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          source: "in_app_report",
          status: "open",
          appVersion,
          platform,
        });
      }

      tx.set(
        unlockRef,
        {
          unlockedAt: admin.firestore.FieldValue.serverTimestamp(),
          reason: "reported_blocked_level",
          fromLevelId: levelId,
        },
        { merge: true },
      );

      const updatePayload = {
        reportedLevelIds: reportedIds.includes(levelId)
          ? reportedIds
          : [...reportedIds, levelId],
        lastReportedLevelId: levelId,
        lastReportedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      if (nextLevelIndex !== null) {
        updatePayload.highestLevelReached = Math.max(currentHighest, nextLevelIndex);
      }

      tx.set(userRef, updatePayload, { merge: true });

      if (nextLevelIndex !== null) {
        tx.set(
          progressRef,
          {
            highestLevelReached: Math.max(currentHighest, nextLevelIndex),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }
    });

    let emailSent = false;
    try {
      const userSnap = await userRef.get();
      const userData = userSnap.data() || {};
      const playerName = normalizeString(userData.playerName) || "unknown";
      const username = normalizeString(userData.username) || "unknown";

      const resend = new Resend(RESEND_API_KEY.value());
      await resend.emails.send({
        from: RESEND_FROM,
        to: SUPPORT_EMAIL,
        subject: "Level Report - TracePath",
        text: [
          "Nuevo reporte de nivel (in-app).",
          `uid: ${uid}`,
          `playerName: ${playerName}`,
          `username: ${username}`,
          `levelId: ${levelId}`,
          `nextLevelId: ${nextLevelId}`,
          `reason: ${reason}`,
          `platform: ${platform}`,
          `appVersion: ${appVersion}`,
          `source: in_app_report`,
        ].join("\n"),
      });
      emailSent = true;
    } catch (e) {
      console.error("[report-level] email send failed (non-blocking):", e);
    }

    return {
      ok: true,
      reportCreated,
      unlocked: true,
      emailSent,
      levelId,
      nextLevelId,
    };
  },
);
