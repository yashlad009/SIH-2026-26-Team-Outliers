const admin = require('firebase-admin');
require('dotenv').config();

let db = null;

try {
  const projectId = process.env.FIREBASE_PROJECT_ID || 'sih2026-27';
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY
    ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
    : null;

  if (clientEmail && privateKey && !privateKey.includes('DEMO_KEY')) {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        clientEmail,
        privateKey,
      }),
    });
    db = admin.firestore();
    console.log(`[Firebase Admin] Authenticated with Service Account for project: ${projectId}`);
  } else {
    console.log(`[Firebase Admin] No service account key found. Using fallback mock store for offline/demo mode.`);
    db = null;
  }
} catch (err) {
  console.warn(`[Firebase Admin Warning] Initialization failed: ${err.message}. Using fallback mock store.`);
  db = null;
}

module.exports = { admin, db };
