const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const policy = require('../lib/zero_trust_policy');

test('session tokens are one-way SHA-256 hashes', () => {
  assert.equal(policy.hashSessionToken('secret-token'), crypto.createHash('sha256').update('secret-token').digest('hex'));
  assert.notEqual(policy.hashSessionToken('secret-token'), 'secret-token');
});

test('risk scores are server-defined and capped', () => {
  assert.deepEqual(policy.scoreSignals(['emulator_detected', 'unknown']), { score: 30, threats: ['emulator_detected'] });
  assert.equal(policy.scoreSignals(['package_name_mismatch', 'signature_mismatch']).score, 100);
});

test('step-up freshness rejects stale and future authentication', () => {
  const now = 2_000_000;
  assert.equal(policy.isFreshAuthentication(1_900, now), true);
  assert.equal(policy.isFreshAuthentication(1_000, now), false);
  assert.equal(policy.isFreshAuthentication(2_100, now), false);
});

test('step-up tickets are bound to uid, action, id and expiry', () => {
  const secret = 'a'.repeat(32);
  const token = policy.signStepUpGrant(secret, 'u1', 'admin_moderation', 'g1', 123);
  assert.notEqual(token, policy.signStepUpGrant(secret, 'u2', 'admin_moderation', 'g1', 123));
  assert.notEqual(token, policy.signStepUpGrant(secret, 'u1', 'guide_payout', 'g1', 123));
});
