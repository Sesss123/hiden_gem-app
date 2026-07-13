/**
 * Zenith Security Nexus — Backend Decision Engine
 * 
 * These functions handle the "Source of Truth" security logic that was
 * migrated from the mobile app to prevent client-side tampering.
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';

admin.initializeApp();

const HMAC_SECRET = process.env.HMAC_SECRET || 'ZENITH_EXPIRY_SIGN_KEY_2026'; // Security Fix: Using env secrets/config

/**
 * 🛡️ verify_entitlements
 * Decides if a user is truly premium.
 */
export const verify_entitlements = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Nexus login required.');
    
    const uid = context.auth.uid;
    const userDoc = await admin.firestore().collection('users').doc(uid).get();
    const userData = userDoc.data();

    if (!userData) return { isPremium: false, role: 'user' };

    // Real billing/subscription logic would go here
    const isPremium = userData.isPremium === true;
    let premiumExpiresAt = Date.now();
    if (userData.premiumExpiresAt) {
        premiumExpiresAt = typeof userData.premiumExpiresAt.toMillis === 'function' 
            ? userData.premiumExpiresAt.toMillis() 
            : new Date(userData.premiumExpiresAt).getTime();
    } else if (userData.subExpiresAt) {
        premiumExpiresAt = typeof userData.subExpiresAt.toMillis === 'function' 
            ? userData.subExpiresAt.toMillis() 
            : new Date(userData.subExpiresAt).getTime();
    }

    // Generate Cryptographic Proof (Point 5)
    const signature = crypto
        .createHmac('sha256', HMAC_SECRET)
        .update(`${uid}|${premiumExpiresAt}`)
        .digest('hex');

    return {
        isPremium,
        role: userData.role || 'user',
        premiumPlanId: userData.premiumPlanId || userData.premiumPlan || userData.subscriptionPlan || 'free',
        premiumExpiresAt,
        signature
    };
});

/**
 * 👮 report_forensic_signals
 * Processes raw signals from the app and calculates the Backend Risk Score.
 */
export const report_forensic_signals = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
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
export const revenuecat_webhook = functions.https.onRequest(async (req: functions.https.Request, res: functions.Response) => {
    // Security: verify the shared secret RevenueCat sends as "Authorization: Bearer <secret>"
    // (configured in RevenueCat dashboard > Project Settings > Webhooks). Without this check,
    // anyone who knows a user's uid could POST a forged event and grant themselves premium.
    const expectedSecret = process.env.REVENUECAT_WEBHOOK_SECRET;
    if (!expectedSecret) {
        console.error("revenuecat_webhook: REVENUECAT_WEBHOOK_SECRET is not configured.");
        res.status(500).send("Server configuration error.");
        return;
    }
    const authHeader = req.header('Authorization') || '';
    const providedSecret = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : authHeader;
    const expectedBuf = Buffer.from(expectedSecret);
    const providedBuf = Buffer.from(providedSecret);
    const isValidSecret = expectedBuf.length === providedBuf.length && crypto.timingSafeEqual(expectedBuf, providedBuf);
    if (!providedSecret || !isValidSecret) {
        res.status(401).send("Unauthorized. Valid RevenueCat webhook secret required.");
        return;
    }

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
        const snapshot = await subscriptionsRef
            .where('accountId', '==', appUserId)
            .limit(1)
            .get();

        let accountType = 'guide';
        let collectionName = 'users';
        let subDocRef: admin.firestore.DocumentReference | null = null;
        let subData: any = {};

        if (!snapshot.empty) {
            subDocRef = snapshot.docs[0].ref;
            subData = snapshot.docs[0].data();
            accountType = subData.accountType || 'guide';
            collectionName = accountType === 'guide' ? 'users' : 'operator_accounts';
        } else {
            const userSnap = await admin.firestore().collection('users').doc(appUserId).get();
            if (userSnap.exists) {
                collectionName = 'users';
                accountType = 'guide';
            } else {
                const opSnap = await admin.firestore().collection('operator_accounts').doc(appUserId).get();
                if (opSnap.exists) {
                    collectionName = 'operator_accounts';
                    accountType = 'operator';
                }
            }
            subDocRef = subscriptionsRef.doc();
        }

        const subUpdateData: any = {
            accountId: appUserId,
            accountType: accountType
        };
        const accountUpdateData: any = {
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        if (type === 'CANCELLATION') {
            subUpdateData.status = 'cancelled';
            subUpdateData.autoRenew = false;
            subUpdateData.cancelledAt = new Date().toISOString();
            
            // CANCELLATION: leave isPremium true until premiumExpiresAt actually passes, but flag autoRenew: false
            accountUpdateData.autoRenew = false;
        } else if (type === 'EXPIRATION') {
            subUpdateData.status = 'expired';
            subUpdateData.autoRenew = false;
            
            // EXPIRATION: set isPremium: false on user/operator doc
            accountUpdateData.isPremium = false;
            accountUpdateData.autoRenew = false;
        } else if (type === 'RENEWAL' || type === 'INITIAL_PURCHASE') {
            subUpdateData.status = 'active';
            subUpdateData.autoRenew = true;
            if (expiresDateMs) {
                subUpdateData.expiresAt = new Date(expiresDateMs).toISOString();
            }
            if (productId) {
                subUpdateData.planId = productId;
            }
            
            // RENEWAL / INITIAL_PURCHASE: set isPremium: true, premiumPlanId, premiumExpiresAt
            accountUpdateData.isPremium = true;
            accountUpdateData.autoRenew = true;
            if (productId) {
                accountUpdateData.premiumPlanId = productId;
                accountUpdateData.premiumPlan = productId;
            } else if (subData.planId) {
                accountUpdateData.premiumPlanId = subData.planId;
                accountUpdateData.premiumPlan = subData.planId;
            }
            if (expiresDateMs) {
                accountUpdateData.premiumExpiresAt = admin.firestore.Timestamp.fromMillis(expiresDateMs);
            }
        }

        if (subDocRef) {
            await subDocRef.set(subUpdateData, { merge: true });
        }
        await admin.firestore().collection(collectionName).doc(appUserId).set(accountUpdateData, { merge: true });
        res.status(200).send("Webhook processed successfully.");
    } catch (error) {
        console.error("Error processing RevenueCat webhook:", error);
        res.status(500).send("Internal Server Error");
    }
});

/**
 * ⏰ daily_subscription_safety_net
 * Runs daily to expire old subscriptions and send renewal reminders.
 */
export const daily_subscription_safety_net = functions.pubsub.schedule('0 0 * * *').onRun(async (context: functions.EventContext) => {
    const now = new Date();
    const threeDaysFromNow = new Date();
    threeDaysFromNow.setDate(now.getDate() + 3);

    const subscriptionsRef = admin.firestore().collection('subscriptions');
    const activeSubsSnap = await subscriptionsRef.where('status', '==', 'active').get();

    for (const doc of activeSubsSnap.docs) {
        const subData = doc.data();
        const accountId = subData.accountId;
        if (!accountId || !subData.expiresAt) continue;

        const expiresAt = new Date(subData.expiresAt);
        const accountType = subData.accountType || 'guide';
        const collectionName = accountType === 'guide' ? 'users' : 'operator_accounts';
        const accountRef = admin.firestore().collection(collectionName).doc(accountId);

        // 1. Check for Expiration (Safety Net)
        if (expiresAt <= now) {
            console.log(`[SafetyNet] Expiring subscription for account ${accountId}`);
            await doc.ref.update({
                status: 'expired',
                autoRenew: false,
                expiredNoticeSentAt: new Date().toISOString()
            });
            await accountRef.update({
                isPremium: false,
                autoRenew: false,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // Send Expiration Notice (Bug 5)
            if (!subData.expiredNoticeSentAt) {
                const title = "Subscription Expired";
                const body = "Your plan has expired — renew now to restore full access.";
                await admin.firestore().collection('user_notifications').add({
                    recipientId: accountId,
                    title,
                    body,
                    isRead: false,
                    type: "subscription_expired",
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });

                const userSnap = await accountRef.get();
                const fcmToken = userSnap.data()?.fcmToken;
                if (fcmToken) {
                    try {
                        await admin.messaging().send({
                            token: fcmToken,
                            notification: { title, body }
                        });
                    } catch (e) {
                        console.error(`Failed to send expiration FCM to ${accountId}:`, e);
                    }
                }
            }
            continue;
        }

        // 2. Check for Renewal Reminder (within next 3 days) (Bug 4)
        if (expiresAt <= threeDaysFromNow && !subData.reminderSentAt) {
            const daysLeft = Math.ceil((expiresAt.getTime() - now.getTime()) / (1000 * 3600 * 24));
            const planId = subData.planId || subData.subscriptionPlan || 'Premium';
            const title = "Subscription Reminder";
            const body = `Your ${planId} plan expires in ${daysLeft} day${daysLeft === 1 ? '' : 's'} — renew to keep your benefits.`;

            console.log(`[SafetyNet] Sending renewal reminder to ${accountId}`);
            await doc.ref.update({
                reminderSentAt: new Date().toISOString()
            });

            await admin.firestore().collection('user_notifications').add({
                recipientId: accountId,
                title,
                body,
                isRead: false,
                type: "subscription_reminder",
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            const userSnap = await accountRef.get();
            const fcmToken = userSnap.data()?.fcmToken;
            if (fcmToken) {
                try {
                    await admin.messaging().send({
                        token: fcmToken,
                        notification: { title, body }
                    });
                } catch (e) {
                    console.error(`Failed to send reminder FCM to ${accountId}:`, e);
                }
            }
        }
    }
});

/**
 * 👁️ track_profile_view
 * Increments a guide listing's profileViews counter server-side.
 * Firestore rules deliberately block client writes to this field (it must
 * not be trustable/inflatable by whoever is viewing the profile), so the
 * increment has to happen here with admin privileges instead.
 *
 * COST FIX: previously incremented on every single call with no dedup —
 * a tourist re-opening the same guide's profile repeatedly in one session
 * (or the same day) counted as a fresh view each time, both inflating the
 * metric (a "view count" should reasonably mean unique interest, not
 * screen-open count) and writing to Firestore on every open. Now checks a
 * small per-(viewer, listing) marker doc with a 24h TTL before
 * incrementing — repeat views within the same day are free (read-only,
 * no write), collapsing to at most one write per viewer per listing per
 * day.
 */
export const track_profile_view = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required.');

    const listingId = data?.listingId;
    if (!listingId || typeof listingId !== 'string') {
        throw new functions.https.HttpsError('invalid-argument', 'listingId is required.');
    }

    const viewerUid = context.auth.uid;
    const markerRef = admin.firestore().collection('profile_view_markers').doc(`${listingId}_${viewerUid}`);
    const listingRef = admin.firestore().collection('guide_listings').doc(listingId);
    const dayMs = 24 * 60 * 60 * 1000;
    const now = Date.now();

    // Read-check-write wrapped in a transaction: without this, two
    // concurrent calls (client retry, double navigation) can both read the
    // marker as stale before either writes it back, both pass the dedup
    // check, and both increment profileViews — defeating the dedup this
    // function exists to enforce.
    const counted = await admin.firestore().runTransaction(async (tx) => {
        const markerSnap = await tx.get(markerRef);
        const lastViewedAtMs = markerSnap.exists ? (markerSnap.data()?.lastViewedAtMs as number | undefined) : undefined;
        if (lastViewedAtMs && now - lastViewedAtMs < dayMs) {
            // Already counted within the last 24h — no-op, no write.
            return false;
        }
        tx.update(listingRef, { profileViews: admin.firestore.FieldValue.increment(1) });
        tx.set(markerRef, { lastViewedAtMs: now }, { merge: true });
        return true;
    });

    return { ok: true, counted };
});

/**
 * 📍 detectLocationSpoof
 * Records a location spoofing incident and flags the user if threshold is reached.
 */
export const detectLocationSpoof = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');

    const uid = context.auth.uid;
    const { reason, detectedSpeed, lat, lng } = data;

    const userRef = admin.firestore().collection('users').doc(uid);
    const postureRef = userRef.collection('security').doc('posture');

    const postureDoc = await postureRef.get();
    let spoofCount = postureDoc.exists ? (postureDoc.data()?.spoofCount || 0) : 0;
    
    spoofCount += 1;
    const flagged = spoofCount >= 3;

    await postureRef.set({
        spoofCount,
        lastSpoofReason: reason,
        lastSpoofSpeed: detectedSpeed || null,
        lastSpoofLocation: new admin.firestore.GeoPoint(lat || 0, lng || 0),
        lastSpoofAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    if (flagged) {
        await userRef.set({ isFlagged: true }, { merge: true });
    }

    return { flagged, spoofCount };
});

/**
 * 🔑 validateJoinToken
 * Rate-limited lookup for a tour_sessions join token — the tourist app's
 * QR/6-char-code join flow (TourSessionRepository.validateAndJoin) used to
 * run this lookup as a bare, unthrottled client-side Firestore query. The
 * token's character set gives ~30 bits of entropy, which is not brute-forceable
 * by hand but IS by a scripted client with no rate limit in the way — this
 * wraps the lookup in a per-user attempt counter (5 attempts / 10 minutes,
 * matching the token's own expiry window) before revealing whether ANY
 * token guess matched, so a script can't cheaply enumerate the ~1 billion
 * possible codes. The actual join transaction (touristIds/redeemedCount
 * update) still happens client-side afterward via the existing atomic
 * transaction in validateAndJoin — this function only gates the lookup.
 */
export const validateJoinToken = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required to join a tour.');
    const token = (data?.token || '').toString().trim().toUpperCase();
    if (!token) throw new functions.https.HttpsError('invalid-argument', 'A join code is required.');

    const uid = context.auth.uid;
    const attemptRef = admin.firestore().collection('join_attempts').doc(uid);
    const windowMs = 10 * 60 * 1000; // 10 minutes — matches token expiry window
    const maxAttempts = 5;
    const now = Date.now();

    const attemptDoc = await attemptRef.get();
    const attemptData = attemptDoc.exists ? attemptDoc.data()! : { count: 0, windowStartedAt: now };
    const windowStartedAt = attemptData.windowStartedAt || now;
    const withinWindow = now - windowStartedAt < windowMs;
    const currentCount = withinWindow ? (attemptData.count || 0) : 0;

    if (withinWindow && currentCount >= maxAttempts) {
        throw new functions.https.HttpsError('resource-exhausted', 'Too many join attempts. Please wait a few minutes and try again.');
    }

    await attemptRef.set({
        count: currentCount + 1,
        windowStartedAt: withinWindow ? windowStartedAt : now,
    }, { merge: true });

    const snapshot = await admin.firestore()
        .collection('tour_sessions')
        .where('joinToken', '==', token)
        .where('isJoinOpen', '==', true)
        .limit(1)
        .get();

    if (snapshot.empty) {
        return { found: false };
    }

    const doc = snapshot.docs[0];
    // On a real match, reset the counter so a legitimate user isn't
    // penalized for earlier typos once they get it right.
    await attemptRef.set({ count: 0, windowStartedAt: now }, { merge: true });
    return { found: true, sessionId: doc.id };
});

