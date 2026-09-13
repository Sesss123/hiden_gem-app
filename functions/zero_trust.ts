/**
 * 🛡️ ZERO-TRUST SECURITY NEXUS (Upgrades 1 - 5)
 * 
 * 1. Device-Bound Cryptographic Sessions (Asymmetric ECDSA P-256 Key Binding)
 * 2. Refresh Token Rotation & Token Family Tracking (Theft Detection)
 * 3. Server-Side Authoritative Risk & Policy Engine
 * 4. Real-time Session Revocation & Maximum Session Age Limits
 * 5. Step-Up Authentication Grants for High-Risk Actions
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';

const HMAC_SECRET = process.env.HMAC_SECRET || 'hidden_gems_dev_hmac_secret_key_12345';

/**
 * 🔑 register_device_key (Phase 1)
 * Binds an ECDSA P-256 Public Key (SPKI PEM) to the authenticated user's device.
 * Stolen access tokens used from another device without the matching private key are rejected.
 */
export const register_device_key = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    const uid = context.auth.uid;
    const deviceId = (data?.deviceId || '').toString().trim();
    const publicKeyPem = (data?.publicKeyPem || '').toString().trim();
    const platform = (data?.platform || 'unknown').toString().trim();
    const model = (data?.model || '').toString().trim();

    if (!deviceId || !publicKeyPem) {
        throw new functions.https.HttpsError('invalid-argument', 'deviceId and publicKeyPem are required.');
    }

    if (!publicKeyPem.includes('BEGIN PUBLIC KEY') || !publicKeyPem.includes('END PUBLIC KEY')) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid Public Key PEM format.');
    }

    const deviceRef = admin.firestore()
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId);

    await deviceRef.set({
        deviceId,
        publicKeyPem,
        platform,
        model,
        boundAt: admin.firestore.FieldValue.serverTimestamp(),
        lastActiveAt: admin.firestore.FieldValue.serverTimestamp(),
        isRevoked: false
    }, { merge: true });

    return { success: true, deviceId };
});

/**
 * 🔄 rotate_session_token (Phase 2 & 4)
 * Enforces Refresh Token Rotation and Token Family Theft Detection.
 * If a previously consumed refresh token is presented again (theft/replay),
 * the entire token family/session is immediately revoked.
 */
export const rotate_session_token = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
    const uid = context.auth.uid;
    const sessionId = (data?.sessionId || '').toString().trim();
    const presentedTokenHash = (data?.presentedTokenHash || '').toString().trim();
    const deviceId = (data?.deviceId || '').toString().trim();

    if (!sessionId || !presentedTokenHash) {
        throw new functions.https.HttpsError('invalid-argument', 'sessionId and presentedTokenHash are required.');
    }

    const sessionRef = admin.firestore()
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId);

    const sessionDoc = await sessionRef.get();
    if (!sessionDoc.exists) {
        // Create initial session if this is the first rotation
        const initialToken = crypto.randomBytes(32).toString('hex');
        const initialTokenHash = crypto.createHash('sha256').update(initialToken).digest('hex');

        await sessionRef.set({
            sessionId,
            deviceId: deviceId || 'unknown',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            lastSeenAt: admin.firestore.FieldValue.serverTimestamp(),
            currentActiveTokenHash: initialTokenHash,
            consumedTokenHashes: [],
            isRevoked: false
        });

        return {
            success: true,
            newToken: initialToken,
            newTokenHash: initialTokenHash,
            expiresInSeconds: 3600
        };
    }

    const sessionData = sessionDoc.data()!;

    if (sessionData.isRevoked) {
        throw new functions.https.HttpsError('permission-denied', 'Session has been revoked.');
    }

    // Check Maximum Session Age (14 days absolute timeout)
    const createdAtMs = sessionData.createdAt?.toMillis ? sessionData.createdAt.toMillis() : Date.now();
    const maxSessionLifetimeMs = 14 * 24 * 60 * 60 * 1000;
    if (Date.now() - createdAtMs > maxSessionLifetimeMs) {
        await sessionRef.set({
            isRevoked: true,
            revocationReason: 'session_expired_max_age',
            revokedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
        throw new functions.https.HttpsError('deadline-exceeded', 'Session expired. Please log in again.');
    }

    const currentHash = sessionData.currentActiveTokenHash;
    const consumedHashes: string[] = sessionData.consumedTokenHashes || [];

    // DETECT TOKEN THEFT: If presented token was already consumed or doesn't match active token
    if (consumedHashes.includes(presentedTokenHash) || (currentHash && currentHash !== presentedTokenHash)) {
        console.error(`🚨 TOKEN REUSE BREACH DETECTED for user ${uid}, session ${sessionId}`);
        
        await sessionRef.set({
            isRevoked: true,
            revocationReason: 'token_reuse_theft_detected',
            revokedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        // Update security posture to blocked
        await admin.firestore()
            .collection('users')
            .doc(uid)
            .collection('security')
            .doc('posture')
            .set({
                riskScore: 100,
                isBlocked: true,
                breachAlert: 'Stolen refresh token reuse attempt detected',
                lastBreachAt: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });

        throw new functions.https.HttpsError('permission-denied', 'Security breach detected: token reuse. Session terminated.');
    }

    // Generate new rotating token
    const newToken = crypto.randomBytes(32).toString('hex');
    const newTokenHash = crypto.createHash('sha256').update(newToken).digest('hex');

    await sessionRef.set({
        previousTokenHash: presentedTokenHash,
        currentActiveTokenHash: newTokenHash,
        consumedTokenHashes: admin.firestore.FieldValue.arrayUnion(presentedTokenHash),
        lastSeenAt: admin.firestore.FieldValue.serverTimestamp(),
        deviceId: deviceId || sessionData.deviceId || 'unknown'
    }, { merge: true });

    return {
        success: true,
        newToken,
        newTokenHash,
        expiresInSeconds: 3600
    };
});

/**
 * 🧠 evaluate_security_posture (Phase 3)
 * Authoritative Server-Side Risk & ABAC Policy Engine.
 * Client sends raw telemetry; server computes the authoritative score and stores posture.
 */
export const evaluate_security_posture = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) return { riskScore: 100, isBlocked: true, level: 'critical' };
    const uid = context.auth.uid;
    const signals = (data?.signals as string[]) || [];
    const deviceId = (data?.deviceId || '').toString();

    let riskScore = 0;
    const activeThreats: string[] = [];

    if (signals.includes('device_rooted_jailbroken')) {
        riskScore += 50;
        activeThreats.push('root_or_jailbreak');
    }
    if (signals.includes('package_name_mismatch')) {
        riskScore += 90;
        activeThreats.push('repackaged_clone_apk');
    }
    if (signals.includes('signature_mismatch')) {
        riskScore += 80;
        activeThreats.push('invalid_app_signature');
    }
    if (signals.includes('debugger_attached')) {
        riskScore += 40;
        activeThreats.push('runtime_debugger_or_hook');
    }
    if (signals.includes('emulator_detected')) {
        riskScore += 30;
        activeThreats.push('emulator_environment');
    }
    if (signals.includes('mock_location_detected')) {
        riskScore += 35;
        activeThreats.push('mock_gps_spoofing');
    }
    if (signals.includes('honeypot_triggered')) {
        riskScore += 70;
        activeThreats.push('honeypot_trap_tripped');
    }

    // Threat Correlation: Root + Debugger = Active Reverse Engineering
    if (signals.includes('device_rooted_jailbroken') && signals.includes('debugger_attached')) {
        riskScore = Math.max(riskScore, 95);
        activeThreats.push('active_reverse_engineering');
    }

    const isBlocked = riskScore >= 90;
    const isRestricted = riskScore >= 50;
    const level = riskScore < 30 ? 'normal' : riskScore < 60 ? 'medium' : riskScore < 90 ? 'high' : 'critical';

    await admin.firestore()
        .collection('users')
        .doc(uid)
        .collection('security')
        .doc('posture')
        .set({
            riskScore,
            level,
            isBlocked,
            isRestricted,
            activeThreats,
            deviceId,
            signals,
            evaluatedAt: admin.firestore.FieldValue.serverTimestamp(),
            engineVersion: 'ZeroTrust-PolicyEngine-3.0'
        }, { merge: true });

    return {
        riskScore,
        level,
        isBlocked,
        isRestricted,
        activeThreats
    };
});

/**
 * 🛑 revoke_session & revoke_all_sessions (Phase 4)
 * Allows users to revoke a specific session or immediately logout from all devices.
 */
export const revoke_session = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required.');
    const uid = context.auth.uid;
    const sessionId = (data?.sessionId || '').toString().trim();
    if (!sessionId) throw new functions.https.HttpsError('invalid-argument', 'sessionId is required.');

    await admin.firestore()
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId)
        .set({
            isRevoked: true,
            revocationReason: 'user_requested_revocation',
            revokedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

    return { success: true };
});

export const revoke_all_sessions = functions.https.onCall(async (_data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required.');
    const uid = context.auth.uid;

    const sessionsSnapshot = await admin.firestore()
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .where('isRevoked', '==', false)
        .get();

    const batch = admin.firestore().batch();
    sessionsSnapshot.docs.forEach(doc => {
        batch.update(doc.ref, {
            isRevoked: true,
            revocationReason: 'user_logged_out_all_devices',
            revokedAt: admin.firestore.FieldValue.serverTimestamp()
        });
    });

    await batch.commit();
    return { success: true, count: sessionsSnapshot.size };
});

/**
 * 🔒 issue_step_up_grant (Phase 5)
 * Step-Up Authentication for high-risk operations (e.g. change email/password, admin actions, guide payouts).
 * Valid for 10 minutes only.
 */
export const issue_step_up_grant = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required.');

    const uid = context.auth.uid;
    const action = (data?.action || '').toString().trim();
    const deviceId = (data?.deviceId || '').toString().trim();

    const allowedActions = [
        'change_email',
        'change_password',
        'admin_moderation',
        'guide_payout',
        'subscription_change'
    ];

    if (!allowedActions.includes(action)) {
        throw new functions.https.HttpsError('invalid-argument', `Invalid action: ${action}`);
    }

    const postureDoc = await admin.firestore()
        .collection('users')
        .doc(uid)
        .collection('security')
        .doc('posture')
        .get();

    if (postureDoc.exists && postureDoc.data()?.isBlocked === true) {
        throw new functions.https.HttpsError('permission-denied', 'Device is blocked by security posture.');
    }

    const grantId = crypto.randomBytes(16).toString('hex');
    const expiresAt = Date.now() + 10 * 60 * 1000;

    const grantToken = crypto.createHmac('sha256', HMAC_SECRET)
        .update(`${uid}|${action}|${grantId}|${expiresAt}`)
        .digest('hex');

    await admin.firestore()
        .collection('users')
        .doc(uid)
        .collection('step_up_grants')
        .doc(grantId)
        .set({
            grantId,
            action,
            deviceId,
            expiresAt,
            isUsed: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

    return {
        grantId,
        grantToken,
        expiresAt,
        action
    };
});
