/**
 * RescueTN Cloud Functions
 * Handles Firebase Cloud Messaging (FCM) push notifications for emergency alerts
 * 
 * Triggers:
 * 1. sendAlertNotifications: Triggered when a new alert is added to emergency_alerts collection
 * 2. updateUserFCMToken: Updates user FCM token in Firestore
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function: sendAlertNotifications
 * 
 * Triggers when a new alert document is created in the 'emergency_alerts' collection
 * Sends FCM push notifications to users based on alert recipientGroups
 * 
 * Alert document structure:
 * {
 *   title: string,
 *   message: string,
 *   level: 'info' | 'warning' | 'severe',
 *   recipientGroups: ['volunteers', 'public', 'admins'],
 *   createdAt: Timestamp,
 *   sentBy: string (user ID),
 *   sentByName: string
 * }
 */
exports.sendAlertNotifications = functions.firestore
  .document('emergency_alerts/{alertId}')
  .onCreate(async (snap, context) => {
    try {
      const alert = snap.data();
      const alertId = snap.id;

      console.log(`📢 New alert created: ${alertId}`);
      console.log(`Alert data:`, alert);

      // Validate alert data
      if (!alert.title || !alert.message || !alert.level) {
        console.error('❌ Invalid alert data - missing required fields');
        return null;
      }

      // Determine recipient groups (default to all users if not specified)
      const recipientGroups = alert.recipientGroups && alert.recipientGroups.length > 0
        ? alert.recipientGroups
        : ['volunteers', 'public'];

      console.log(`📤 Sending to recipient groups:`, recipientGroups);

      // Build FCM topic list based on recipient groups
      const topics = recipientGroups.map(role => {
        switch (role.toLowerCase()) {
          case 'admin':
          case 'admins':
            return 'admin-users';
          case 'volunteer':
          case 'volunteers':
            return 'volunteer-users';
          case 'public':
            return 'public-users';
          default:
            return `${role}-users`;
        }
      });

      // Add common topic for all users
      topics.push('all-users');

      console.log(`🎯 FCM Topics:`, topics);

      // Determine notification priority and icon based on alert level
      const priorityMap = {
        'severe': 'high',
        'warning': 'high',
        'info': 'normal'
      };

      const colorMap = {
        'severe': '#D32F2F',   // Red
        'warning': '#F57C00',  // Orange
        'info': '#1976D2'      // Blue
      };

      const priority = priorityMap[alert.level] || 'normal';
      const color = colorMap[alert.level] || '#1976D2';

      // Create multicast message for each topic
      const messages = topics.map(topic => ({
        notification: {
          title: alert.title,
          body: alert.message,
        },
        data: {
          alertId: alertId,
          level: alert.level,
          title: alert.title,
          message: alert.message,
          timestamp: new Date().toISOString(),
          sentBy: alert.sentBy || 'system',
          sentByName: alert.sentByName || 'RescueTN',
        },
        android: {
          priority: priority,
          notification: {
            title: alert.title,
            body: alert.message,
            color: color,
            icon: 'ic_launcher_foreground',
            sound: 'default',
            channelId: alert.level === 'severe' ? 'emergency' : 'alerts',
            defaultSound: true,
            defaultVibrate: true,
          },
          ttl: 86400, // 24 hours
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: alert.title,
                body: alert.message,
              },
              badge: 1,
              sound: 'default',
              category: alert.level === 'severe' ? 'EMERGENCY_ALERT' : 'REGULAR_ALERT',
            },
          },
        },
        webpush: {
          notification: {
            title: alert.title,
            body: alert.message,
            icon: 'https://rescuetn.example.com/icon.png',
            badge: 'https://rescuetn.example.com/badge.png',
            tag: `alert-${alertId}`,
            requireInteraction: alert.level === 'severe',
          },
          data: {
            alertId: alertId,
            level: alert.level,
          },
        },
      }));

      // Send notifications to all topics
      let totalSent = 0;
      let totalFailed = 0;

      for (const message of messages) {
        try {
          const topicName = topics[messages.indexOf(message)];
          const response = await messaging.send({
            ...message,
            topic: topicName,
          });

          console.log(`✅ Successfully sent notification to topic '${topicName}': ${response}`);
          totalSent++;
        } catch (error) {
          console.error(`❌ Error sending to topic '${topics[messages.indexOf(message)]}':`, error.message);
          totalFailed++;
        }
      }

      // Log summary
      console.log(`📊 Notification Summary:`);
      console.log(`   Sent: ${totalSent}, Failed: ${totalFailed}`);

      // Update alert with notification status
      await db.collection('emergency_alerts').doc(alertId).update({
        notificationsSent: totalSent,
        notificationsFailed: totalFailed,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'delivered',
      });

      console.log(`✅ Alert ${alertId} processed successfully`);
      return { sent: totalSent, failed: totalFailed };

    } catch (error) {
      console.error('❌ Error in sendAlertNotifications:', error);
      // Re-throw to mark function as failed
      throw error;
    }
  });

/**
 * Cloud Function: updateUserFCMToken
 * 
 * HTTP endpoint to update user's FCM token in Firestore
 * Called by the mobile app when FCM token is refreshed
 * 
 * Request body:
 * {
 *   userId: string,
 *   token: string
 * }
 */
exports.updateUserFCMToken = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      // Verify request method
      if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
      }

      const { userId, token } = req.body;

      // Validate input
      if (!userId || !token) {
        return res.status(400).json({ error: 'Missing userId or token' });
      }

      // Verify Firebase ID token (optional but recommended)
      // For now, we'll just update the token
      // In production, verify the ID token from Authorization header

      // Update user's FCM token in Firestore
      await db.collection('users').doc(userId).update({
        fcmToken: token,
        fcmTokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ FCM token updated for user: ${userId}`);

      return res.status(200).json({
        success: true,
        message: 'FCM token updated successfully',
      });

    } catch (error) {
      console.error('❌ Error updating FCM token:', error);
      return res.status(500).json({
        error: 'Failed to update FCM token',
        details: error.message,
      });
    }
  });
});

/**
 * Cloud Function: handleNotificationClick
 * 
 * HTTP endpoint to track when users click on notifications
 * Useful for analytics and measuring engagement
 */
exports.handleNotificationClick = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
      }

      const { userId, alertId, action } = req.body;

      if (!userId || !alertId) {
        return res.status(400).json({ error: 'Missing userId or alertId' });
      }

      // Log the click event
      await db.collection('alerts').doc(alertId).collection('interactions').add({
        userId,
        action: action || 'click',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ Notification interaction logged: ${userId} -> ${alertId}`);

      return res.status(200).json({
        success: true,
        message: 'Interaction logged',
      });

    } catch (error) {
      console.error('❌ Error logging notification click:', error);
      return res.status(500).json({ error: 'Failed to log interaction' });
    }
  });
});

/**
 * Cloud Function: broadcastAlert
 * 
 * HTTP endpoint to manually send an alert (admin only)
 * Used for testing and urgent manual alerts
 */
exports.broadcastAlert = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
      }

      const { title, message, level, recipientGroups } = req.body;

      // Validate input
      if (!title || !message || !level) {
        return res.status(400).json({
          error: 'Missing required fields: title, message, level',
        });
      }

      // Validate alert level
      if (!['info', 'warning', 'severe'].includes(level)) {
        return res.status(400).json({
          error: 'Invalid level. Must be: info, warning, or severe',
        });
      }

      // Create alert in Firestore (this will trigger sendAlertNotifications)
      const alertRef = await db.collection('emergency_alerts').add({
        title,
        message,
        level,
        recipientGroups: recipientGroups || ['volunteers', 'public'],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        sentBy: 'system',
        sentByName: 'RescueTN Admin',
        status: 'pending',
      });

      console.log(`✅ Alert created and queued for broadcast: ${alertRef.id}`);

      return res.status(200).json({
        success: true,
        alertId: alertRef.id,
        message: 'Alert created and notifications are being sent',
      });

    } catch (error) {
      console.error('❌ Error in broadcastAlert:', error);
      return res.status(500).json({
        error: 'Failed to create alert',
        details: error.message,
      });
    }
  });
});
