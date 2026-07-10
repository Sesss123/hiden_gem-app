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
 */
export const track_profile_view = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required.');

    const listingId = data?.listingId;
    if (!listingId || typeof listingId !== 'string') {
        throw new functions.https.HttpsError('invalid-argument', 'listingId is required.');
    }

    await admin.firestore().collection('guide_listings').doc(listingId).update({
        profileViews: admin.firestore.FieldValue.increment(1),
    });

    return { ok: true };
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

