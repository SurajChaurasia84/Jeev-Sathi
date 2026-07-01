import { db, messaging } from '../lib/firebase.js';

/**
 * POST /api/notify-all
 *
 * Broadcasts a push notification to all users.
 * Uses FCM Topic 'sos_alerts' as high-reliability fallback if Firestore token read fails.
 *
 * Request body:
 * {
 *   "reporterId": "uid-of-the-sos-poster",
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

  const { reporterId, title, body, latitude, longitude, data = {} } = req.body ?? {};

  if (!title || !body) {
    return res.status(400).json({ error: 'title and body are required' });
  }

  try {
    let tokens = [];
    let usedTopicFallback = false;

    // ── Try fetching tokens from Firestore ───────────────────────────────
    try {
      const usersSnap = await db.collection('users').get();
      usersSnap.forEach((doc) => {
        const userData = doc.data();
        const token = userData.fcmToken;
        if (!token || token.trim() === '') return;
        if (reporterId && doc.id === reporterId) return;

        // Apply 5 km radius filtering if coordinates are provided
        if (latitude !== undefined && longitude !== undefined && latitude !== null && longitude !== null) {
          const userLat = userData.latitude;
          const userLng = userData.longitude;
          if (userLat === undefined || userLng === undefined || userLat === null || userLng === null) {
            // Skip user since we don't know their location
            return;
          }
          const dist = getDistanceInKm(
            Number(latitude),
            Number(longitude),
            Number(userLat),
            Number(userLng)
          );
          if (dist > 5.0) return; // Skip if distance > 5 km
        }

        tokens.push(token);
      });
    } catch (dbErr) {
      console.warn('Firestore read warning, using FCM topic fallback:', dbErr.message);
      usedTopicFallback = true;
    }

    const payloadAndroid = {
      notification: {
        icon: 'ic_stat_pets',
        color: '#10B981',
        sound: 'default',
        channelId: 'high_importance_channel',
      },
      priority: 'high',
    };

    const payloadApns = {
      payload: {
        aps: { sound: 'default', badge: 1 },
      },
    };

    const payloadData = {
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
      ...Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
    };

    let totalSuccess = 0;
    let totalFailure = 0;

    if (!usedTopicFallback && tokens.length > 0) {
      const BATCH_SIZE = 500;
      for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
        const batch = tokens.slice(i, i + BATCH_SIZE);
        const message = {
          tokens: batch,
          notification: { title, body },
          android: payloadAndroid,
          apns: payloadApns,
          data: payloadData,
        };
        const response = await messaging.sendEachForMulticast(message);
        totalSuccess += response.successCount;
        totalFailure += response.failureCount;
      }
    } else {
      // Send via FCM Topic 'sos_alerts'
      const topicMessage = {
        topic: 'sos_alerts',
        notification: { title, body },
        android: payloadAndroid,
        apns: payloadApns,
        data: payloadData,
      };
      await messaging.send(topicMessage);
      totalSuccess = 1;
    }

    // ── Store notification record in Firestore (safely ignored if permission denied) ──
    try {
      await db.collection('notifications').add({
        type: 'broadcast',
        title,
        body,
        data,
        excludedUid: reporterId ?? null,
        sentAt: new Date(),
        successCount: totalSuccess,
        usedTopicFallback,
      });
    } catch (_) {}

    return res.status(200).json({
      success: true,
      sent: totalSuccess,
      usedTopicFallback,
    });
  } catch (err) {
    console.error('notify-all error:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
}

function getDistanceInKm(lat1, lon1, lat2, lon2) {
  const R = 6371; // Radius of the earth in km
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c; // Distance in km
}
