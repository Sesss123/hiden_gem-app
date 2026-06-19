/**
 * Zenith Security Nexus — Backend Decision Engine
 * 
 * These functions handle the "Source of Truth" security logic that was
 * migrated from the mobile app to prevent client-side tampering.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';

admin.initializeApp();

const HMAC_SECRET = 'ZENITH_EXPIRY_SIGN_KEY_2026'; // Synchronization Key

/**
 * 🛡️ verify_entitlements
 * Decides if a user is truly premium.
 */
export const verify_entitlements = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Nexus login required.');
    
    const uid = context.auth.uid;
    const userDoc = await admin.firestore().collection('users').doc(uid).get();
    const userData = userDoc.data();

    if (!userData) return { isPremium: false, role: 'user' };

    // Real billing/subscription logic would go here
    const isPremium = userData.isPremium === true;
    const premiumExpiresAt = userData.premiumExpiresAt?.toMillis() || Date.now();

    // Generate Cryptographic Proof (Point 5)
    const signature = crypto
        .createHmac('sha256', HMAC_SECRET)
        .update(`${uid}|${premiumExpiresAt}`)
        .digest('hex');

    return {
        isPremium,
        role: userData.role || 'user',
        premiumExpiresAt,
        signature
    };
});

/**
 * 👮 report_forensic_signals
 * Processes raw signals from the app and calculates the Backend Risk Score.
 */
export const report_forensic_signals = functions.https.onCall(async (data, context) => {
    if (!context.auth) return { riskScore: 100 }; // Unauth reporting is critical risk
    
    const uid = context.auth.uid;
    const signals = data.signals as string[];
    
    let riskScore = 0;
    
    // Server-Side Risk Matrix
    if (signals.includes('device_rooted_jailbroken')) riskScore += 50;
    if (signals.includes('package_name_mismatch')) riskScore += 90;
    if (signals.includes('emulator_detected')) riskScore += 30;
    if (signals.includes('debugger_attached')) riskScore += 40;

    // Update Security Posture (Real-time override)
    await admin.firestore()
        .collection('users')
        .doc(uid)
        .collection('security')
        .doc('posture')
        .set({
            riskScore,
            isBlocked: riskScore >= 90,
            lastScan: admin.firestore.FieldValue.serverTimestamp(),
            signals: signals
        }, { merge: true });

    return { riskScore };
});
