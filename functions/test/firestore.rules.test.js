const { before, after, beforeEach, test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

let env;
const projectId = 'hidden-gems-rules-test';
const [firestoreHost, firestorePort] =
  (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8085').split(':');

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: firestoreHost,
      port: Number(firestorePort),
      rules: fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8'),
    },
  });
});

after(async () => env && env.cleanup());
beforeEach(async () => env.clearFirestore());

async function seed(pathName, data) {
  await env.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(pathName).set(data);
  });
}

test('a user cannot read another private profile', async () => {
  await seed('users/bob', { role: 'user', isPremium: false });
  const alice = env.authenticatedContext('alice').firestore();
  await assertFails(alice.doc('users/bob').get());
});

test('account creation cannot self-grant admin or premium', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  await assertFails(alice.doc('users/alice').set({ role: 'admin', isPremium: true }));
  await assertSucceeds(alice.doc('users/alice').set({ role: 'user', isPremium: false }));
});

test('an existing user cannot forge privileged fields or subscriptions', async () => {
  await seed('users/alice', { role: 'user', isPremium: false });
  const alice = env.authenticatedContext('alice').firestore();
  await assertFails(alice.doc('users/alice').update({ role: 'admin' }));
  await assertFails(alice.doc('users/alice').update({ isPremium: true }));
  await assertFails(alice.doc('subscriptions/fake').set({ accountId: 'alice', status: 'active' }));
});

test('only a real tour participant can create an SOS audit record', async () => {
  await seed('users/alice', { role: 'user' });
  await seed('users/bob', { role: 'user' });
  await seed('tour_sessions/session1', { guideId: 'guide', touristIds: ['alice'], sosActive: false });
  const shape = { sessionId: 'session1', status: 'triggered', timestamp: new Date() };
  const alice = env.authenticatedContext('alice').firestore();
  const bob = env.authenticatedContext('bob').firestore();
  await assertSucceeds(alice.doc('sos_alerts/valid').set({ ...shape, triggeredBy: 'alice' }));
  await assertFails(bob.doc('sos_alerts/forged').set({ ...shape, triggeredBy: 'bob' }));
});

test('clients cannot enqueue administrator topic notifications', async () => {
  await seed('users/alice', { role: 'user' });
  const alice = env.authenticatedContext('alice').firestore();
  await assertFails(alice.doc('pending_notifications/forged').set({
    topic: 'security-admins', status: 'queued', title: 'forged', body: 'forged',
  }));
});

test('clients cannot forge critical security alerts', async () => {
  await seed('users/alice', { role: 'user' });
  const alice = env.authenticatedContext('alice').firestore();
  await assertFails(alice.doc('security_alerts/forged').set({
    userId: 'alice', code: 'forged', severity: 'critical', status: 'open',
  }));
  await assertFails(alice.doc('threat_notifications/forged').set({
    uid: 'alice', category: 'SPECTRE', severity: 'critical', status: 'active',
    signals: ['forged'], appVersion: '1', buildNumber: '1', details: 'forged',
  }));
});

test('clients cannot forge device trust bindings', async () => {
  await seed('users/alice', { role: 'user' });
  const alice = env.authenticatedContext('alice').firestore();
  await assertFails(alice.doc('device_trust/random_alice').set({
    uid: 'alice', deviceHash: 'random', platform: 'android',
  }));
});

test('family booking guest count and package capacity are enforced', async () => {
  await seed('users/tourist', { role: 'user' });
  await seed('guide_listings/guide', {
    guideId: 'guide', status: 'published', moderationStatus: 'approved',
  });
  await seed('tour_packages/pkg', {
    ownerId: 'guide', isActive: true, maxGuests: 4,
  });
  const tourist = env.authenticatedContext('tourist').firestore();
  const booking = {
    bookingId: 'booking-ok', touristId: 'tourist', guideId: 'guide',
    packageId: 'pkg', guestCount: 4, status: 'pending', payoutStatus: 'pending',
  };
  await assertSucceeds(tourist.doc('booking_requests/booking-ok').set(booking));
  await assertFails(tourist.doc('booking_requests/booking-too-large').set({
    ...booking, bookingId: 'booking-too-large', guestCount: 5,
  }));
  await assertFails(tourist.doc('booking_requests/booking-invalid').set({
    ...booking, bookingId: 'booking-invalid', packageId: null, guestCount: 21,
  }));
});

test('tourists cannot forge payment or refund fields', async () => {
  await seed('users/tourist', { role: 'user' });
  await seed('booking_requests/booking', {
    touristId: 'tourist', guideId: 'guide', status: 'session_ready',
    payoutStatus: 'pending', quotedPrice: 1000,
  });
  const tourist = env.authenticatedContext('tourist').firestore();
  await assertFails(tourist.doc('booking_requests/booking').update({
    payoutStatus: 'paid', paymentStatus: 'paid', paidAmount: 1000,
  }));
  await assertFails(tourist.doc('booking_requests/booking').update({
    refundStatus: 'completed', refundedAt: new Date().toISOString(),
  }));
});

test('reviews require a real paid completed booking linked to the session', async () => {
  await seed('users/tourist', { role: 'user' });
  await seed('tour_sessions/session', {
    bookingId: 'booking', guideId: 'guide', touristIds: ['tourist'],
    reviewEligibleTouristIds: ['tourist'], status: 'completed',
  });
  const review = {
    sessionId: 'session', touristId: 'tourist', guideId: 'guide',
    moderationStatus: 'under_review', comment: 'Good', overallRating: 5,
    knowledgeRating: 5, communicationRating: 5, punctualityRating: 5,
    safetyRating: 5, friendlinessRating: 5,
  };
  const tourist = env.authenticatedContext('tourist').firestore();
  await assertFails(tourist.doc('tour_reviews/session_tourist').set(review));
  await seed('booking_requests/booking', {
    linkedSessionId: 'session', touristId: 'tourist', guideId: 'guide',
    payoutStatus: 'paid', status: 'completed',
  });
  await assertSucceeds(tourist.doc('tour_reviews/session_tourist').set(review));
});

test('family QR joins cannot be performed by a direct client write', async () => {
  await seed('tour_sessions/session', {
    guideId: 'guide', touristIds: ['owner'], redeemedCount: 1,
    maxTourists: 2, isLocked: false, currentPhase: 'assembling',
  });
  const member = env.authenticatedContext('member').firestore();
  await assertFails(member.doc('tour_sessions/session').update({
    touristIds: ['owner', 'member'], redeemedCount: 2,
  }));

  await seed('tour_sessions/duplicate', {
    guideId: 'guide', touristIds: ['owner', 'member'], redeemedCount: 2,
    maxTourists: 3, isLocked: false, currentPhase: 'assembling',
  });
  await assertFails(member.doc('tour_sessions/duplicate').update({
    touristIds: ['owner', 'member'], redeemedCount: 3,
  }));

  await seed('tour_sessions/full', {
    guideId: 'guide', touristIds: ['owner', 'other'], redeemedCount: 2,
    maxTourists: 2, isLocked: false, currentPhase: 'assembling',
  });
  await assertFails(member.doc('tour_sessions/full').update({
    touristIds: ['owner', 'other', 'member'], redeemedCount: 3,
  }));
});

test('open tour sessions are not enumerable by unrelated users', async () => {
  await seed('tour_sessions/session', {
    guideId: 'guide', touristIds: ['owner'], redeemedCount: 1,
    maxTourists: 2, isJoinOpen: true, currentPhase: 'assembling',
  });
  const stranger = env.authenticatedContext('stranger').firestore();
  await assertFails(stranger.doc('tour_sessions/session').get());
});
