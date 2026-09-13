"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.issue_step_up_grant = exports.revoke_all_sessions = exports.revoke_session = exports.evaluate_security_posture = exports.rotate_session_token = exports.register_device_key = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
const crypto = __importStar(require("crypto"));
const zero_trust_policy_1 = require("./zero_trust_policy");
const db = () => admin.firestore();
function requireAuth(context) {
    if (!context.auth)
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
    return context.auth.uid;
}
function stepUpSecret() {
    const secret = process.env.STEP_UP_HMAC_SECRET;
    if (!secret || secret.length < 32) {
        throw new functions.https.HttpsError('failed-precondition', 'Step-up signing secret is not securely configured.');
    }
    return secret;
}
exports.register_device_key = functions.https.onCall(async (data, context) => {
    const uid = requireAuth(context);
    if (!context.app && process.env.FUNCTIONS_EMULATOR !== 'true') {
        throw new functions.https.HttpsError('failed-precondition', 'Valid App Check attestation required.');
    }
    const deviceId = String((data === null || data === void 0 ? void 0 : data.deviceId) || '').trim();
    const publicKeyPem = String((data === null || data === void 0 ? void 0 : data.publicKeyPem) || '').trim();
    const platform = String((data === null || data === void 0 ? void 0 : data.platform) || 'unknown').trim();
    const model = String((data === null || data === void 0 ? void 0 : data.model) || '').trim();
    if (!deviceId || !publicKeyPem)
        throw new functions.https.HttpsError('invalid-argument', 'deviceId and publicKeyPem are required.');
    try {
        crypto.createPublicKey(publicKeyPem);
    }
    catch (_) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid public key.');
    }
    const ref = db().collection('users').doc(uid).collection('devices').doc(deviceId);
    await db().runTransaction(async (tx) => {
        var _a, _b, _c;
        const existing = await tx.get(ref);
        if (existing.exists && ((_a = existing.data()) === null || _a === void 0 ? void 0 : _a.keyVersion) === 'native-v1' && ((_b = existing.data()) === null || _b === void 0 ? void 0 : _b.publicKeyPem) !== publicKeyPem) {
            throw new functions.https.HttpsError('permission-denied', 'Device key replacement requires explicit revocation.');
        }
        tx.set(ref, {
            deviceId, publicKeyPem, platform, model,
            boundAt: existing.exists ? (_c = existing.data()) === null || _c === void 0 ? void 0 : _c.boundAt : admin.firestore.FieldValue.serverTimestamp(),
            lastActiveAt: admin.firestore.FieldValue.serverTimestamp(), isRevoked: false, keyVersion: 'native-v1'
        }, { merge: true });
    });
    return { success: true, deviceId };
});
exports.rotate_session_token = functions.https.onCall(async (data, context) => {
    var _a, _b;
    const uid = requireAuth(context);
    const sessionId = String((data === null || data === void 0 ? void 0 : data.sessionId) || '').trim();
    const presentedHash = String((data === null || data === void 0 ? void 0 : data.presentedTokenHash) || '').trim();
    const deviceId = String((data === null || data === void 0 ? void 0 : data.deviceId) || '').trim();
    if (!sessionId || !deviceId)
        throw new functions.https.HttpsError('invalid-argument', 'sessionId and deviceId are required.');
    const device = await db().collection('users').doc(uid).collection('devices').doc(deviceId).get();
    if (!device.exists || ((_a = device.data()) === null || _a === void 0 ? void 0 : _a.isRevoked) === true) {
        throw new functions.https.HttpsError('permission-denied', 'Device key is not registered or was revoked.');
    }
    const ref = db().collection('users').doc(uid).collection('sessions').doc(sessionId);
    const newToken = crypto.randomBytes(32).toString('base64url');
    const newHash = (0, zero_trust_policy_1.hashSessionToken)(newToken);
    const ipHash = crypto.createHash('sha256').update(`${context.rawRequest.ip}|${process.env.GCLOUD_PROJECT || 'hidden-gems'}`).digest('hex');
    const userAgent = String(context.rawRequest.header('user-agent') || '').slice(0, 256);
    let replay = false;
    await db().runTransaction(async (tx) => {
        var _a, _b, _c;
        const snapshot = await tx.get(ref);
        if (!snapshot.exists) {
            if (presentedHash)
                throw new functions.https.HttpsError('permission-denied', 'Unknown session.');
            tx.create(ref, {
                sessionId, familyId: crypto.randomUUID(), deviceId,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                lastSeenAt: admin.firestore.FieldValue.serverTimestamp(),
                currentActiveTokenHash: newHash, consumedTokenHashes: [], isRevoked: false,
                ipHash, userAgent
            });
            return;
        }
        const session = snapshot.data();
        if (session.isRevoked)
            throw new functions.https.HttpsError('permission-denied', 'Session is revoked.');
        if (session.deviceId !== deviceId)
            replay = true;
        const created = (_c = (_b = (_a = session.createdAt) === null || _a === void 0 ? void 0 : _a.toMillis) === null || _b === void 0 ? void 0 : _b.call(_a)) !== null && _c !== void 0 ? _c : Date.now();
        if (Date.now() - created > 12 * 60 * 60 * 1000) {
            tx.update(ref, { isRevoked: true, revocationReason: 'maximum_age', revokedAt: admin.firestore.FieldValue.serverTimestamp() });
            throw new functions.https.HttpsError('deadline-exceeded', 'Session expired.');
        }
        const consumed = session.consumedTokenHashes || [];
        if (!presentedHash || session.currentActiveTokenHash !== presentedHash || consumed.includes(presentedHash))
            replay = true;
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
        const tokens = ((_b = profile.data()) === null || _b === void 0 ? void 0 : _b.fcmTokens) || [];
        if (tokens.length)
            await admin.messaging().sendEachForMulticast({
                tokens: tokens.slice(0, 500),
                notification: { title: 'Security alert', body: 'A reused session token was blocked.' },
                data: { type: 'security_session_revoked' }
            }).catch(error => console.error('Security notification failed', error));
        throw new functions.https.HttpsError('permission-denied', 'Token reuse detected; session revoked.');
    }
    return { success: true, newToken, newTokenHash: newHash, expiresInSeconds: 3600 };
});
exports.evaluate_security_posture = functions.https.onCall(async (data, context) => {
    var _a, _b, _c, _d, _e;
    const uid = requireAuth(context);
    const signals = Array.isArray(data === null || data === void 0 ? void 0 : data.signals) ? data.signals.filter((v) => typeof v === 'string').slice(0, 50) : [];
    const deviceId = String((data === null || data === void 0 ? void 0 : data.deviceId) || '');
    const action = String((data === null || data === void 0 ? void 0 : data.action) || 'general');
    const [user, device, activeSessions] = await Promise.all([
        db().collection('users').doc(uid).get(),
        deviceId ? db().collection('users').doc(uid).collection('devices').doc(deviceId).get() : Promise.resolve(null),
        deviceId ? db().collection('users').doc(uid).collection('sessions').where('deviceId', '==', deviceId).where('isRevoked', '==', false).limit(1).get() : Promise.resolve(null)
    ]);
    const scored = (0, zero_trust_policy_1.scoreSignals)(signals);
    let riskScore = scored.score;
    const threats = scored.threats;
    if (!context.app) {
        riskScore += 40;
        threats.push('app_check_missing');
    }
    if (!device || !device.exists || ((_a = device.data()) === null || _a === void 0 ? void 0 : _a.isRevoked)) {
        riskScore += 60;
        threats.push('untrusted_device');
    }
    if (!activeSessions || activeSessions.empty) {
        riskScore += 40;
        threats.push('no_active_session');
    }
    riskScore = Math.min(100, riskScore);
    const role = ((_b = user.data()) === null || _b === void 0 ? void 0 : _b.role) || ((_c = context.auth) === null || _c === void 0 ? void 0 : _c.token.role) || 'tourist';
    const entitlement = ((_d = user.data()) === null || _d === void 0 ? void 0 : _d.subscriptionPlan) || ((_e = user.data()) === null || _e === void 0 ? void 0 : _e.subscriptionTier) || 'Free';
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
exports.revoke_session = functions.https.onCall(async (data, context) => {
    const uid = requireAuth(context);
    const sessionId = String((data === null || data === void 0 ? void 0 : data.sessionId) || '').trim();
    if (!sessionId)
        throw new functions.https.HttpsError('invalid-argument', 'sessionId is required.');
    await db().collection('users').doc(uid).collection('sessions').doc(sessionId).set({
        isRevoked: true, revocationReason: 'user_requested', revokedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    return { success: true };
});
exports.revoke_all_sessions = functions.https.onCall(async (_data, context) => {
    const uid = requireAuth(context);
    const sessions = await db().collection('users').doc(uid).collection('sessions').where('isRevoked', '==', false).get();
    const batch = db().batch();
    sessions.docs.forEach(doc => batch.update(doc.ref, {
        isRevoked: true, revocationReason: 'user_requested_all', revokedAt: admin.firestore.FieldValue.serverTimestamp()
    }));
    await batch.commit();
    return { success: true, count: sessions.size };
});
exports.issue_step_up_grant = functions.https.onCall(async (data, context) => {
    var _a, _b, _c;
    const uid = requireAuth(context);
    const action = String((data === null || data === void 0 ? void 0 : data.action) || '').trim();
    const deviceId = String((data === null || data === void 0 ? void 0 : data.deviceId) || '').trim();
    const allowedActions = ['change_email', 'change_password', 'admin_moderation', 'guide_payout', 'subscription_change'];
    if (!allowedActions.includes(action))
        throw new functions.https.HttpsError('invalid-argument', 'Invalid action.');
    const authTime = Number(((_a = context.auth) === null || _a === void 0 ? void 0 : _a.token.auth_time) || 0);
    if (!(0, zero_trust_policy_1.isFreshAuthentication)(authTime, Date.now()))
        throw new functions.https.HttpsError('unauthenticated', 'Fresh authentication required.');
    const [posture, device] = await Promise.all([
        db().collection('users').doc(uid).collection('security').doc('posture').get(),
        db().collection('users').doc(uid).collection('devices').doc(deviceId).get()
    ]);
    if (((_b = posture.data()) === null || _b === void 0 ? void 0 : _b.isBlocked) || !device.exists || ((_c = device.data()) === null || _c === void 0 ? void 0 : _c.isRevoked))
        throw new functions.https.HttpsError('permission-denied', 'Device is not trusted.');
    const grantId = crypto.randomBytes(16).toString('hex');
    const expiresAt = Date.now() + 10 * 60 * 1000;
    const grantToken = (0, zero_trust_policy_1.signStepUpGrant)(stepUpSecret(), uid, action, grantId, expiresAt);
    await db().collection('users').doc(uid).collection('step_up_grants').doc(grantId).set({
        grantId, action, deviceId, expiresAt, isUsed: false, createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    return { grantId, grantToken, expiresAt, action };
});
//# sourceMappingURL=zero_trust.js.map