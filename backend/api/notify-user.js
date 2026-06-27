import { db, messaging } from '../lib/firebase.js';

/**
 * POST /api/notify-user
 *
 * Sends a targeted push notification to a single device token or user.
 *
 * Request body:
 * {
 *   "targetToken": "fcm-device-token",  ← direct token (preferred)
 *   "targetUid": "uid-of-recipient",    ← fallback lookup
 *   "title": "✅ आपकी SOS स्वीकार की गई",
 *   "body": "एक गौ सेवक आपकी सहायता के लिए आ रहे हैं।",
 *   "data": { "type": "sos_accepted", "id": "ABC123" }
 * }
 *
 * Protected by x-api-secret header.
 */
export default async function handler(req, res) {
  // ── Method guard ──────────────────────────────────────────────────────────
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // ── Auth guard ────────────────────────────────────────────────────────────
  const secret = req.headers['x-api-secret'];
  if (!process.env.API_SECRET || secret !== process.env.API_SECRET) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const { targetToken, token, targetUid, title, body, data = {} } = req.body ?? {};

  if (!title || !body) {
    return res.status(400).json({ error: 'title and body are required' });
  }

  let recipientToken = targetToken || token;

  // If no direct token provided, try looking up from Firestore
  if (!recipientToken && targetUid) {
    try {
      const userDoc = await db.collection('users').doc(targetUid).get();
      if (userDoc.exists) {
        recipientToken = userDoc.data()?.fcmToken;
      }
    } catch (dbErr) {
      console.warn('Firestore user lookup warning (ignored):', dbErr.message);
    }
  }

  if (!recipientToken || recipientToken.trim() === '') {
    return res.status(200).json({ success: true, message: 'No valid FCM token provided or found, skipped' });
  }

  try {
    // ── Build and send the FCM message ────────────────────────────────────
    const message = {
      token: recipientToken,
      notification: { title, body },
      android: {
        notification: {
          icon: 'ic_stat_pets',
          color: '#10B981',
          sound: 'default',
          channelId: 'high_importance_channel',
        },
        priority: 'high',
      },
      apns: {
        payload: {
          aps: { sound: 'default', badge: 1 },
        },
      },
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        ...Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, String(v)])
        ),
      },
    };

    const messageId = await messaging.send(message);

    // ── Store notification record in Firestore (safely ignored if permission denied) ──
    try {
      await db.collection('notifications').add({
        type: 'targeted',
        targetUid: targetUid ?? null,
        title,
        body,
        data,
        sentAt: new Date(),
        messageId,
      });
    } catch (dbErr) {
      console.warn('Firestore write warning (ignored):', dbErr.message);
    }

    return res.status(200).json({ success: true, messageId });
  } catch (err) {
    console.error('notify-user FCM error:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
}
