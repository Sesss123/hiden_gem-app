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

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
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
