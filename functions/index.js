const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * When a notification event is created for a user, send a push (FCM) to that user's device.
 * Path: notifications/{userId}/events/{eventId}
 */
exports.sendPushOnNotificationEvent = functions.firestore
  .document("notifications/{userId}/events/{eventId}")
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const eventId = context.params.eventId;
    const data = snap.data();

    const title = data.title || "Notification";
    const body = data.body || "";
    const payloadData = data.data || {};
    // Ensure data keys are strings for FCM
    const fcmData = {};
    for (const [k, v] of Object.entries(payloadData)) {
      fcmData[k] = typeof v === "string" ? v : JSON.stringify(v);
    }
    fcmData.type = data.type || "systemAlert";
    fcmData.id = eventId;

    let fcmToken;
    try {
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      fcmToken = userDoc.exists ? userDoc.data().fcmToken : null;
    } catch (e) {
      functions.logger.warn("Failed to get FCM token for user " + userId, e);
      return null;
    }

    if (!fcmToken) {
      functions.logger.log("No FCM token for user " + userId + ", skip push");
      return null;
    }

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title,
          body,
          sound: "default",
        },
        data: fcmData,
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channelId: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
          fcmOptions: {},
        },
      });
      functions.logger.log("Push sent to user " + userId + " for event " + eventId);
      return null;
    } catch (e) {
      functions.logger.error("Failed to send push to user " + userId, e);
      return null;
    }
  });
