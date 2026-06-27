import { db, messaging } from '../lib/firebase.js';

/**
 * POST /api/notify-all
 *
 * Broadcasts a push notification to ALL installed users EXCEPT the SOS poster.
 *
 * Request body:
 * {
 *   "reporterId": "uid-of-the-sos-poster",   ← excluded from notification
 *   "title": "🚨 आपातकालीन अलर्ट: Cow रेस्क्यू",
 *   "body": "मदद की आवश्यकता है।",
 *   "data": { "type": "sos", "id": "ABC123" }
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

  const { reporterId, title, body, data = {} } = req.body ?? {};

  if (!title || !body) {
    return res.status(400).json({ error: 'title and body are required' });
  }

  try {
    // ── Fetch all FCM tokens from Firestore ───────────────────────────────
    const usersSnap = await db.collection('users').get();

    const tokens = [];
    usersSnap.forEach((doc) => {
      const userData = doc.data();
      const token = userData.fcmToken;

      // Skip if: no token, token is empty, or this is the SOS poster
      if (!token || token.trim() === '') return;
      if (reporterId && doc.id === reporterId) return; // ← exclude poster

      tokens.push(token);
    });

    if (tokens.length === 0) {
      return res.status(200).json({ success: true, sent: 0, message: 'No eligible tokens found' });
    }

    // FCM allows max 500 tokens per multicast batch
    const BATCH_SIZE = 500;
    let totalSuccess = 0;
    let totalFailure = 0;

    for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
      const batch = tokens.slice(i, i + BATCH_SIZE);

      const message = {
        tokens: batch,
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

      const response = await messaging.sendEachForMulticast(message);
      totalSuccess += response.successCount;
      totalFailure += response.failureCount;
    }

    // ── Store notification record in Firestore ────────────────────────────
    await db.collection('notifications').add({
      type: 'broadcast',
      title,
      body,
      data,
      excludedUid: reporterId ?? null,
      sentAt: new Date(),
      successCount: totalSuccess,
      failureCount: totalFailure,
    });

    return res.status(200).json({
      success: true,
      sent: totalSuccess,
      failed: totalFailure,
    });
  } catch (err) {
    console.error('notify-all error:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
}
