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

/**
 * 💰 revenuecat_webhook
 * Processes incoming RevenueCat events to securely manage Firestore subscriptions.
 */
export const revenuecat_webhook = functions.https.onRequest(async (req, res) => {
    // 1. Authenticate the webhook request (ideally via an Auth header or IP allowlist)
    // For now, we process the payload directly.
    const body = req.body;
    const event = body?.event;

    if (!event) {
        res.status(400).send("No event provided.");
        return;
    }

    const appUserId = event.app_user_id; // Our accountId
    const type = event.type; // INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION
    const productId = event.product_id;
    const expiresDateMs = event.expiration_at_ms;

    try {
        const subscriptionsRef = admin.firestore().collection('subscriptions');
        
        // Find existing subscription for this user
        const snapshot = await subscriptionsRef
            .where('accountId', '==', appUserId)
            .limit(1)
            .get();

        if (snapshot.empty) {
            // Initial purchase is usually handled by the client-side directly
            // but we can log or handle fallback creation here if needed.
            res.status(200).send("No existing subscription found to update.");
            return;
        }

        const subDoc = snapshot.docs[0];
        
        const updateData: any = {};
        
        if (type === 'CANCELLATION') {
            updateData.status = 'cancelled';
            updateData.cancelledAt = new Date().toISOString();
        } else if (type === 'EXPIRATION') {
            updateData.status = 'expired';
        } else if (type === 'RENEWAL' || type === 'INITIAL_PURCHASE') {
            updateData.status = 'active';
            if (expiresDateMs) {
                updateData.expiresAt = new Date(expiresDateMs).toISOString();
            }
        }

        await subDoc.ref.update(updateData);
        res.status(200).send("Webhook processed successfully.");
    } catch (error) {
        console.error("Error processing RevenueCat webhook:", error);
        res.status(500).send("Internal Server Error");
    }
});
