const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

/**
 * Initializes Firebase Admin using the same service account as the Python backend.
 */
function initFirebase() {
  if (admin.apps.length > 0) return admin.app();

  // Try to find the service account key
  // We'll look in the backend directory since we know it exists there
  const serviceAccountPath = path.join(__dirname, '../../../backend/serviceAccountKey.json');

  if (fs.existsSync(serviceAccountPath)) {
    try {
      const serviceAccount = require(serviceAccountPath);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      console.log('[GENESIS] Firebase Admin Link Established');
    } catch (err) {
      console.error('[GENESIS] Firebase Auth Error:', err.message);
    }
  } else {
    console.warn('[GENESIS] Warning: serviceAccountKey.json not found. External auth may fail.');
  }

  return admin;
}

module.exports = initFirebase;
