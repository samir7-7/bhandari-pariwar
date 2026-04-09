const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

function isInvalidRegistrationError(errorCode) {
  return (
    errorCode === "messaging/invalid-registration-token" ||
    errorCode === "messaging/registration-token-not-registered"
  );
}

async function cleanupInvalidTokens(tokenDocs, responses) {
  const batch = db.batch();
  let hasDeletes = false;

  responses.forEach((response, index) => {
    if (!response.success && isInvalidRegistrationError(response.error?.code)) {
      const token = tokenDocs[index]?.token;
      if (token) {
        batch.delete(db.collection("device_tokens").doc(token));
        hasDeletes = true;
      }
    }
  });

  if (hasDeletes) {
    await batch.commit();
  }
}

async function sendToTokenDocs(tokenDocs, payload) {
  if (!tokenDocs.length) {
    return 0;
  }

  let sentCount = 0;

  for (let i = 0; i < tokenDocs.length; i += 500) {
    const chunkDocs = tokenDocs.slice(i, i + 500).filter((doc) => doc.token);
    if (!chunkDocs.length) {
      continue;
    }

    const result = await messaging.sendEachForMulticast({
      tokens: chunkDocs.map((doc) => doc.token),
      ...payload,
    });

    await cleanupInvalidTokens(chunkDocs, result.responses || []);
    sentCount += chunkDocs.length;
  }

  return sentCount;
}

async function getAllTokenDocs() {
  const tokensSnap = await db.collection("device_tokens").get();
  return tokensSnap.docs
    .map((doc) => doc.data())
    .filter((doc) => doc.token);
}

async function getUserTokenDocs(uid) {
  const tokensSnap = await db
    .collection("device_tokens")
    .where("uid", "==", uid)
    .get();

  return tokensSnap.docs
    .map((doc) => doc.data())
    .filter((doc) => doc.token);
}

async function deleteUserTokens(uid) {
  const tokensSnap = await db
    .collection("device_tokens")
    .where("uid", "==", uid)
    .get();

  if (tokensSnap.empty) {
    return;
  }

  const batch = db.batch();
  tokensSnap.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
}

/**
 * Triggered when a new notice is created in Firestore.
 * Sends a push notification to all registered device tokens.
 */
exports.onNoticeCreated = functions.firestore
  .document("notices/{noticeId}")
  .onCreate(async (snap, context) => {
    const notice = snap.data();

    if (!notice.notifyUsers) {
      console.log("Notice created without notification flag, skipping push.");
      return null;
    }

    const title = notice.title?.en || "New Announcement";
    const bodyText = notice.body?.en || "";
    const preview =
      bodyText.length > 100 ? `${bodyText.substring(0, 100)}...` : bodyText;

    const tokenDocs = await getAllTokenDocs();
    if (!tokenDocs.length) {
      console.log("No device tokens found, skipping push.");
      return null;
    }

    const sentCount = await sendToTokenDocs(tokenDocs, {
      notification: {
        title: title,
        body: preview,
      },
      data: {
        type: "notice",
        noticeId: context.params.noticeId,
        screen: `/notices/${context.params.noticeId}`,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "notices",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });

    console.log(
      `Push notification sent for notice ${context.params.noticeId} to ${sentCount} devices.`,
    );
    return null;
  });

exports.onUserApprovalUpdated = functions.firestore
  .document("app_users/{userId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};

    if (before.status === "approved" || after.status !== "approved") {
      return null;
    }

    const tokenDocs = await getUserTokenDocs(context.params.userId);
    if (!tokenDocs.length) {
      console.log(
        `No device tokens found for approved user ${context.params.userId}.`,
      );
      return change.after.ref.set(
        {
          approvalNotificationSentAt:
            admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    }

    const sentCount = await sendToTokenDocs(tokenDocs, {
      notification: {
        title: "Account approved",
        body: "Your account has been approved. You can use the app now.",
      },
      data: {
        type: "account_approved",
        screen: "/home",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "notices",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });

    await change.after.ref.set(
      {
        approvalNotificationSentAt:
          admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    console.log(
      `Approval notification sent to ${sentCount} devices for user ${context.params.userId}.`,
    );
    return null;
  });

exports.onUserRequestDeleted = functions.firestore
  .document("app_users/{userId}")
  .onDelete(async (snap, context) => {
    const data = snap.data() || {};

    await deleteUserTokens(context.params.userId);

    if (data.role === "admin") {
      console.log(
        `Skipping auth deletion for admin profile ${context.params.userId}.`,
      );
      return null;
    }

    try {
      await admin.auth().deleteUser(context.params.userId);
      console.log(`Deleted auth user ${context.params.userId}.`);
    } catch (error) {
      if (error.code !== "auth/user-not-found") {
        throw error;
      }
      console.log(`Auth user ${context.params.userId} was already deleted.`);
    }

    return null;
  });
