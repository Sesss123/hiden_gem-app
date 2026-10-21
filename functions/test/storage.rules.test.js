const { before, after, beforeEach, test } = require('node:test');
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
const [storageHost, storagePort] =
  (process.env.FIREBASE_STORAGE_EMULATOR_HOST || '127.0.0.1:9195').split(':');

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: firestoreHost,
      port: Number(firestorePort),
      rules: fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8'),
    },
    storage: {
      host: storageHost,
      port: Number(storagePort),
      rules: fs.readFileSync(path.resolve(__dirname, '../../storage.rules'), 'utf8'),
    },
  });
});

after(async () => env && env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
});

async function seedUser(userId, data) {
  await env.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(`users/${userId}`).set(data);
  });
}

async function seedStorage(pathName, contentType = 'application/octet-stream') {
  await env.withSecurityRulesDisabled(async (context) => {
    await context.storage().ref(pathName).putString('seed', 'raw', { contentType });
  });
}

test('avatars restrict writes to the owner and image types', async () => {
  const alice = env.authenticatedContext('alice').storage();
  const bob = env.authenticatedContext('bob').storage();

  await assertSucceeds(alice.ref('avatars/alice/profile.png')
    .putString('image', 'raw', { contentType: 'image/png' }));
  await assertFails(bob.ref('avatars/alice/forged.png')
    .putString('image', 'raw', { contentType: 'image/png' }));
  await assertFails(alice.ref('avatars/alice/profile.txt')
    .putString('text', 'raw', { contentType: 'text/plain' }));
});

test('guide documents are restricted to the owner and admins', async () => {
  await seedUser('admin', { role: 'admin' });
  await seedStorage('guide_documents/alice/license.png', 'image/png');
  const alice = env.authenticatedContext('alice').storage();
  const bob = env.authenticatedContext('bob').storage();
  const admin = env.authenticatedContext('admin').storage();

  await assertSucceeds(alice.ref('guide_documents/alice/license.png').getMetadata());
  await assertFails(bob.ref('guide_documents/alice/license.png').getMetadata());
  await assertSucceeds(admin.ref('guide_documents/alice/license.png').getMetadata());
});

test('premium audio requires premium or admin status', async () => {
  await seedUser('free', { role: 'user', isPremium: false });
  await seedUser('premium', { role: 'user', isPremium: true });
  await seedUser('admin', { role: 'admin', isPremium: false });
  await seedStorage('audio_guides/place.mp3', 'audio/mpeg');

  await assertFails(env.authenticatedContext('free').storage()
    .ref('audio_guides/place.mp3').getMetadata());
  await assertSucceeds(env.authenticatedContext('premium').storage()
    .ref('audio_guides/place.mp3').getMetadata());
  await assertSucceeds(env.authenticatedContext('admin').storage()
    .ref('audio_guides/place.mp3').getMetadata());
});

test('admin uploads and unknown paths default to deny', async () => {
  await seedUser('admin', { role: 'admin' });
  const user = env.authenticatedContext('user').storage();
  const admin = env.authenticatedContext('admin').storage();

  await assertFails(user.ref('admin_uploads/raw.bin').putString('raw'));
  await assertSucceeds(admin.ref('admin_uploads/raw.bin').putString('raw'));
  await assertFails(user.ref('unknown/private.txt').putString('private'));
  await assertFails(env.unauthenticatedContext().storage()
    .ref('location_images/place.png').getMetadata());
});
