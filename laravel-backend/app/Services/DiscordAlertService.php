<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Sole delivery channel for operational alerts (health-check state changes,
 * backup failures) — the app previously had no way to reach anyone at all
 * (no mail delivery, no chat integration wired up anywhere). A Discord
 * webhook needs no bot/OAuth setup, just a URL from a channel's Integrations
 * settings.
 */
class DiscordAlertService
{
    /**
     * Posts $message to the configured webhook. No-ops (logs a warning
     * instead of throwing) if DISCORD_ALERT_WEBHOOK_URL isn't set — a
     * missing webhook URL should degrade to "no alerts," not break the
     * command that tried to send one.
     */
    public function send(string $message, string $level = 'info'): void
    {
        $webhookUrl = config('services.discord.webhook_url');
        if (empty($webhookUrl)) {
            Log::warning('DiscordAlertService: DISCORD_ALERT_WEBHOOK_URL not configured, alert not sent.', ['message' => $message]);
            return;
        }

        $prefix = match ($level) {
            'error' => '🔴',
            'warning' => '🟡',
            'success' => '🟢',
            default => 'ℹ️',
        };

        try {
            Http::timeout(10)->post($webhookUrl, [
                'content' => "{$prefix} **Hidden Gems SL** — {$message}",
            ]);
        } catch (\Exception $e) {
            // Never let a failed alert delivery break the caller's own logic
            // (a backup or health-check command should still finish/exit
            // correctly even if Discord itself is unreachable).
            Log::error('DiscordAlertService: failed to post webhook', ['error' => $e->getMessage()]);
        }
    }
}
