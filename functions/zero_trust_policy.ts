import * as crypto from 'crypto';

export const SIGNAL_WEIGHTS: Readonly<Record<string, number>> = Object.freeze({
    device_rooted_jailbroken: 50,
    package_name_mismatch: 90,
    signature_mismatch: 80,
    debugger_attached: 40,
    emulator_detected: 30,
    mock_location_detected: 35,
    honeypot_triggered: 70
});

export function hashSessionToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
}

export function scoreSignals(signals: readonly string[]): { score: number; threats: string[] } {
    const threats = signals.filter(signal => Boolean(SIGNAL_WEIGHTS[signal]));
    return {
        score: Math.min(100, threats.reduce((total, signal) => total + SIGNAL_WEIGHTS[signal], 0)),
        threats
    };
}

export function isFreshAuthentication(authTimeSeconds: number, nowMs: number, maxAgeMs = 5 * 60 * 1000): boolean {
    const authMs = authTimeSeconds * 1000;
    return authMs > 0 && nowMs >= authMs && nowMs - authMs <= maxAgeMs;
}

export function signStepUpGrant(secret: string, uid: string, action: string, grantId: string, expiresAt: number): string {
    return crypto.createHmac('sha256', secret).update(`${uid}|${action}|${grantId}|${expiresAt}`).digest('hex');
}
