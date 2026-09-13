import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import { hashSessionToken, isFreshAuthentication, scoreSignals, signStepUpGrant } from './zero_trust_policy';

const db = () => admin.firestore();

function requireAuth(context: functions.https.CallableContext): string {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
    return context.auth.uid;
}

function stepUpSecret(): string {
    const secret = process.env.STEP_UP_HMAC_SECRET;
    if (!secret || secret.length < 32) {
        throw new functions.https.HttpsError('failed-precondition', 'Step-up signing secret is not securely configured.');
    }
    return secret;
}

export const register_device_key = functions.https.onCall(async (data: any, context) => {
    const uid = requireAuth(context);
    if (!context.app && process.env.FUNCTIONS_EMULATOR !== 'true') {
        throw new functions.https.HttpsError('failed-precondition', 'Valid App Check attestation required.');
    }
    const deviceId = String(data?.deviceId || '').trim();
    const publicKeyPem = String(data?.publicKeyPem || '').trim();
    const platform = String(data?.platform || 'unknown').trim();
    const model = String(data?.model || '').trim();
    if (!deviceId || !publicKeyPem) throw new functions.https.HttpsError('invalid-argument', 'deviceId and publicKeyPem are required.');
    try {
        crypto.createPublicKey(publicKeyPem);
    } catch (_) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid public key.');
    }
    const ref = db().collection('users').doc(uid).collection('devices').doc(deviceId);
    await db().runTransaction(async tx => {
        const existing = await tx.get(ref);
        if (existing.exists && existing.data()?.keyVersion === 'native-v1' && existing.data()?.publicKeyPem !== publicKeyPem) {
            throw new functions.https.HttpsError('permission-denied', 'Device key replacement requires explicit revocation.');
        }
        tx.set(ref, {
            deviceId, publicKeyPem, platform, model,
            boundAt: existing.exists ? existing.data()?.boundAt : admin.firestore.FieldValue.serverTimestamp(),
            lastActiveAt: admin.firestore.FieldValue.serverTimestamp(), isRevoked: false, keyVersion: 'native-v1'
        }, { merge: true });
    });
    return { success: true, deviceId };
});

export const rotate_session_token = functions.https.onCall(async (data: any, context) => {
    const uid = requireAuth(context);
    const sessionId = String(data?.sessionId || '').trim();
    const presentedHash = String(data?.presentedTokenHash || '').trim();
    const deviceId = String(data?.deviceId || '').trim();
    if (!sessionId || !deviceId) throw new functions.https.HttpsError('invalid-argument', 'sessionId and deviceId are required.');

    const device = await db().collection('users').doc(uid).collection('devices').doc(deviceId).get();
    if (!device.exists || device.data()?.isRevoked === true) {
        throw new functions.https.HttpsError('permission-denied', 'Device key is not registered or was revoked.');
    }

    const ref = db().collection('users').doc(uid).collection('sessions').doc(sessionId);
    const newToken = crypto.randomBytes(32).toString('base64url');
    const newHash = hashSessionToken(newToken);
    const ipHash = crypto.createHash('sha256').update(`${context.rawRequest.ip}|${process.env.GCLOUD_PROJECT || 'hidden-gems'}`).digest('hex');
    const userAgent = String(context.rawRequest.header('user-agent') || '').slice(0, 256);
    let replay = false;

    await db().runTransaction(async tx => {
        const snapshot = await tx.get(ref);
        if (!snapshot.exists) {
            if (presentedHash) throw new functions.https.HttpsError('permission-denied', 'Unknown session.');
            tx.create(ref, {
                sessionId, familyId: crypto.randomUUID(), deviceId,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                lastSeenAt: admin.firestore.FieldValue.serverTimestamp(),
                currentActiveTokenHash: newHash, consumedTokenHashes: [], isRevoked: false,
                ipHash, userAgent
            });
            return;
        }
        const session = snapshot.data()!;
        if (session.isRevoked) throw new functions.https.HttpsError('permission-denied', 'Session is revoked.');
        if (session.deviceId !== deviceId) replay = true;
        const created = session.createdAt?.toMillis?.() ?? Date.now();
        if (Date.now() - created > 12 * 60 * 60 * 1000) {
            tx.update(ref, { isRevoked: true, revocationReason: 'maximum_age', revokedAt: admin.firestore.FieldValue.serverTimestamp() });
            throw new functions.https.HttpsError('deadline-exceeded', 'Session expired.');
        }
        const consumed: string[] = session.consumedTokenHashes || [];
        if (!presentedHash || session.currentActiveTokenHash !== presentedHash || consumed.includes(presentedHash)) replay = true;
        if (replay) {
            tx.update(ref, { isRevoked: true, revocationReason: 'token_reuse', revokedAt: admin.firestore.FieldValue.serverTimestamp() });
            return;
        }
        tx.update(ref, {
            previousTokenHash: presentedHash,
            currentActiveTokenHash: newHash,
            consumedTokenHashes: admin.firestore.FieldValue.arrayUnion(presentedHash),
            lastSeenAt: admin.firestore.FieldValue.serverTimestamp(),
            ipHash, userAgent
        });
    });

    if (replay) {
        await db().collection('users').doc(uid).collection('security').doc('posture').set({
            riskScore: 100, isBlocked: true, breachAlert: 'session_token_reuse',
            lastBreachAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
        const profile = await db().collection('users').doc(uid).get();
        const tokens: string[] = profile.data()?.fcmTokens || [];
        if (tokens.length) await admin.messaging().sendEachForMulticast({
            tokens: tokens.slice(0, 500),
            notification: { title: 'Security alert', body: 'A reused session token was blocked.' },
            data: { type: 'security_session_revoked' }
        }).catch(error => console.error('Security notification failed', error));
        throw new functions.https.HttpsError('permission-denied', 'Token reuse detected; session revoked.');
    }
    return { success: true, newToken, newTokenHash: newHash, expiresInSeconds: 3600 };
});

export const evaluate_security_posture = functions.https.onCall(async (data: any, context) => {
    const uid = requireAuth(context);
    const signals = Array.isArray(data?.signals) ? data.signals.filter((v: unknown) => typeof v === 'string').slice(0, 50) : [];
    const deviceId = String(data?.deviceId || '');
    const action = String(data?.action || 'general');
    const [user, device, activeSessions] = await Promise.all([
        db().collection('users').doc(uid).get(),
        deviceId ? db().collection('users').doc(uid).collection('devices').doc(deviceId).get() : Promise.resolve(null),
        deviceId ? db().collection('users').doc(uid).collection('sessions').where('deviceId', '==', deviceId).where('isRevoked', '==', false).limit(1).get() : Promise.resolve(null)
    ]);
    const scored = scoreSignals(signals);
    let riskScore = scored.score;
    const threats = scored.threats;
    if (!context.app) { riskScore += 40; threats.push('app_check_missing'); }
    if (!device || !device.exists || device.data()?.isRevoked) { riskScore += 60; threats.push('untrusted_device'); }
    if (!activeSessions || activeSessions.empty) { riskScore += 40; threats.push('no_active_session'); }
    riskScore = Math.min(100, riskScore);
    const role = user.data()?.role || context.auth?.token.role || 'tourist';
    const entitlement = user.data()?.subscriptionPlan || user.data()?.subscriptionTier || 'Free';
    const isBlocked = riskScore >= 90;
    const allowed = !isBlocked && !(action.startsWith('admin_') && !['admin', 'super_admin'].includes(role));
    const level = riskScore < 30 ? 'normal' : riskScore < 60 ? 'medium' : riskScore < 90 ? 'high' : 'critical';
    await db().collection('users').doc(uid).collection('security').doc('posture').set({
        riskScore, level, isBlocked, isRestricted: riskScore >= 50, activeThreats: threats,
        deviceId, role, entitlement, lastAction: action, lastDecisionAllowed: allowed,
        evaluatedAt: admin.firestore.FieldValue.serverTimestamp(), engineVersion: 'ZeroTrust-PolicyEngine-4.0'
    }, { merge: true });
    return { riskScore, level, isBlocked, isRestricted: riskScore >= 50, activeThreats: threats, role, entitlement, allowed };
});

export const revoke_session = functions.https.onCall(async (data: any, context) => {
    const uid = requireAuth(context);
    const sessionId = String(data?.sessionId || '').trim();
    if (!sessionId) throw new functions.https.HttpsError('invalid-argument', 'sessionId is required.');
    await db().collection('users').doc(uid).collection('sessions').doc(sessionId).set({
        isRevoked: true, revocationReason: 'user_requested', revokedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    return { success: true };
});

export const revoke_all_sessions = functions.https.onCall(async (_data: any, context) => {
    const uid = requireAuth(context);
    const sessions = await db().collection('users').doc(uid).collection('sessions').where('isRevoked', '==', false).get();
    const batch = db().batch();
    sessions.docs.forEach(doc => batch.update(doc.ref, {
        isRevoked: true, revocationReason: 'user_requested_all', revokedAt: admin.firestore.FieldValue.serverTimestamp()
    }));
    await batch.commit();
    return { success: true, count: sessions.size };
});

export const issue_step_up_grant = functions.https.onCall(async (data: any, context) => {
    const uid = requireAuth(context);
    const action = String(data?.action || '').trim();
    const deviceId = String(data?.deviceId || '').trim();
    const allowedActions = ['change_email', 'change_password', 'admin_moderation', 'guide_payout', 'subscription_change'];
    if (!allowedActions.includes(action)) throw new functions.https.HttpsError('invalid-argument', 'Invalid action.');
    const authTime = Number(context.auth?.token.auth_time || 0);
    if (!isFreshAuthentication(authTime, Date.now())) throw new functions.https.HttpsError('unauthenticated', 'Fresh authentication required.');
    const [posture, device] = await Promise.all([
        db().collection('users').doc(uid).collection('security').doc('posture').get(),
        db().collection('users').doc(uid).collection('devices').doc(deviceId).get()
    ]);
    if (posture.data()?.isBlocked || !device.exists || device.data()?.isRevoked) throw new functions.https.HttpsError('permission-denied', 'Device is not trusted.');
    const grantId = crypto.randomBytes(16).toString('hex');
    const expiresAt = Date.now() + 10 * 60 * 1000;
    const grantToken = signStepUpGrant(stepUpSecret(), uid, action, grantId, expiresAt);
    await db().collection('users').doc(uid).collection('step_up_grants').doc(grantId).set({
        grantId, action, deviceId, expiresAt, isUsed: false, createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    return { grantId, grantToken, expiresAt, action };
});
