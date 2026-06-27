import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Initialize Firebase Admin SDK only once (Vercel reuses function instances)
if (!admin.apps.length) {
  let serviceAccount = null;

  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
      serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    } catch (e) {
      console.error('Failed to parse FIREBASE_SERVICE_ACCOUNT environment variable:', e);
    }
  }

  // Fallback to local service-account.json if env var is not set or failed to parse
  if (!serviceAccount) {
    const localKeyPath = path.resolve(__dirname, '../service-account.json');
    if (fs.existsSync(localKeyPath)) {
      try {
        const fileData = fs.readFileSync(localKeyPath, 'utf8');
        serviceAccount = JSON.parse(fileData);
      } catch (e) {
        console.error('Failed to read local service-account.json:', e);
      }
    }
  }

  if (serviceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  } else {
    console.error('CRITICAL: No Firebase Service Account configuration found!');
  }
}

export const db = admin.firestore();
export const messaging = admin.messaging();
export default admin;
