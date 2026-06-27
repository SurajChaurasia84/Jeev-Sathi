import { db, messaging } from '../lib/firebase.js';

/**
 * POST /api/notify-user
 *
 * Sends a targeted push notification to a single user identified by their UID.
 * Looks up their FCM token from Firestore users/{uid}.fcmToken
 *
 * Request body:
 * {
 *   "targetUid": "uid-of-the-recipient",
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

  const { targetUid, title, body, data = {} } = req.body ?? {};

  if (!targetUid || !title || !body) {
    return res.status(400).json({ error: 'targetUid, title, and body are required' });
  }

  try {
    // ── Look up the target user's FCM token ───────────────────────────────
    const userDoc = await db.collection('users').doc(targetUid).get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken || fcmToken.trim() === '') {
      return res.status(200).json({ success: true, message: 'User has no FCM token, skipped' });
    }

    // ── Build and send the FCM message ────────────────────────────────────
    const message = {
      token: fcmToken,
      notification: { title, body },
      android: {
        notification: {
          icon: 'ic_stat_pets',
          color: '#10B981',
          sound: 'default',
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

    // ── Store notification record in Firestore ────────────────────────────
    await db.collection('notifications').add({
      type: 'targeted',
      targetUid,
      title,
      body,
      data,
      sentAt: new Date(),
      messageId,
    });

    return res.status(200).json({ success: true, messageId });
  } catch (err) {
    console.error('notify-user error:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
}
