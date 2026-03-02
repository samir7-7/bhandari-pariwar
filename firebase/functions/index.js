const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

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
      bodyText.length > 100 ? bodyText.substring(0, 100) + "..." : bodyText;

    // Fetch all device tokens.
    const tokensSnap = await db.collection("device_tokens").get();
    if (tokensSnap.empty) {
      console.log("No device tokens found, skipping push.");
      return null;
    }

    const tokens = tokensSnap.docs.map((doc) => doc.data().token);

    // Send in batches of 500 (FCM limit).
    const batches = [];
    for (let i = 0; i < tokens.length; i += 500) {
      const batch = tokens.slice(i, i + 500);
      batches.push(
        messaging.sendEachForMulticast({
          tokens: batch,
          notification: {
            title: title,
            body: preview,
          },
          data: {
            type: "notice",
            noticeId: context.params.noticeId,
            screen: "/notices/" + context.params.noticeId,
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
        }),
      );
    }

    const results = await Promise.all(batches);

    // Clean up invalid tokens.
    for (const result of results) {
      if (result.responses) {
        result.responses.forEach((resp, idx) => {
          if (
            !resp.success &&
            (resp.error?.code === "messaging/invalid-registration-token" ||
              resp.error?.code ===
                "messaging/registration-token-not-registered")
          ) {
            const invalidToken = tokens[idx];
            db.collection("device_tokens").doc(invalidToken).delete();
            console.log("Removed invalid token:", invalidToken);
          }
        });
      }
    }

    console.log(
      `Push notification sent for notice ${context.params.noticeId} to ${tokens.length} devices.`,
    );
    return null;
  });
