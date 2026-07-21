@php
    $recipientName = $link['recipientName'] ?? 'there';
    $expiresAt = isset($link['expiresAt']) ? \Carbon\Carbon::parse($link['expiresAt']) : null;
@endphp
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    {{-- SOS refresh cadence is decided client-side now (see script below) --
         sosActive lives inside the encrypted blob, which PHP never sees. --}}
    <meta http-equiv="refresh" content="30">
    <title>Trip status — Hidden Gems SL</title>
    <style>
        :root {
            --rust: #C1440E;
            --rust-dim: #E07A3F;
            --earth: #6B4226;
            --bg: #FFFDF8;
            --ink: #2B211B;
            --muted: #8A7B6C;
            --card: #FFFFFF;
            --line: rgba(107, 66, 38, 0.12);
            --sos: #D63031;
        }
        @media (prefers-color-scheme: dark) {
            :root {
                --bg: #1A1512;
                --ink: #F4EDE4;
                --muted: #B3A290;
                --card: #241D18;
                --line: rgba(244, 237, 228, 0.1);
            }
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            min-height: 100vh;
            background: var(--bg);
            color: var(--ink);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            padding: 20px 16px 40px;
        }
        .wrap { max-width: 480px; margin: 0 auto; }
        .eyebrow {
            font-size: 12px; letter-spacing: 0.06em; text-transform: uppercase;
            color: var(--muted); font-weight: 600; margin-bottom: 4px;
        }
        h1 { font-size: 22px; margin: 0 0 24px; font-weight: 700; }
        .sos-banner {
            background: var(--sos);
            color: #fff;
            border-radius: 16px;
            padding: 16px 18px;
            margin-bottom: 20px;
            display: flex; align-items: center; gap: 12px;
            font-weight: 600;
        }
        .sos-banner.hidden { display: none; }
        .sos-banner .dot {
            width: 10px; height: 10px; border-radius: 50%;
            background: #fff;
            animation: pulse 1.4s infinite;
            flex-shrink: 0;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.35; }
        }
        .card {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 18px;
            padding: 20px;
            margin-bottom: 16px;
        }
        .card.hidden { display: none; }
        .card-label {
            font-size: 11px; text-transform: uppercase; letter-spacing: 0.05em;
            color: var(--muted); font-weight: 700; margin-bottom: 10px;
        }
        .status-row { display: flex; align-items: center; gap: 12px; }
        .status-dot {
            width: 12px; height: 12px; border-radius: 50%;
            background: var(--rust); flex-shrink: 0;
        }
        .status-dot.idle { background: var(--muted); }
        .status-text { font-size: 17px; font-weight: 600; }
        .meta-row {
            display: flex; justify-content: space-between; align-items: baseline;
            padding: 10px 0; border-top: 1px solid var(--line);
        }
        .meta-row:first-child { border-top: none; padding-top: 0; }
        .meta-label { font-size: 13px; color: var(--muted); }
        .meta-value { font-size: 14px; font-weight: 600; text-align: right; }
        .footer-note {
            text-align: center; font-size: 12px; color: var(--muted);
            margin-top: 28px; line-height: 1.6;
        }
        .locked-card {
            display: flex; align-items: center; gap: 10px;
            color: var(--muted); font-size: 13px;
        }
        .locked-card.hidden { display: none; }
    </style>
</head>
<body data-encrypted="{{ $encryptedStatus }}">
    <div class="wrap">
        <div class="eyebrow">Hidden Gems SL &middot; Live trip sharing</div>
        <h1>Hi {{ $recipientName }}, here's the latest</h1>

        <div id="sos-banner" class="sos-banner hidden">
            <span class="dot"></span>
            <span>Emergency alert active — the traveler has triggered SOS. This page refreshes automatically.</span>
        </div>

        <div id="no-status-card" class="card locked-card">
            <span>Loading trip status&hellip;</span>
        </div>

        <div id="decrypt-error" class="card locked-card hidden">
            <span>Unable to decrypt trip status — this link may be malformed or out of date.</span>
        </div>

        <div id="status-card" class="card hidden">
            <div class="card-label">Current status</div>
            <div class="status-row">
                <span id="status-dot" class="status-dot"></span>
                <span id="status-text" class="status-text"></span>
            </div>
        </div>

        <div id="guide-card" class="card hidden">
            <div class="card-label">Guide</div>
            <div class="meta-row" style="border-top:none; padding-top:0;">
                <span id="guide-name" class="meta-value"></span>
            </div>
        </div>

        <div id="meeting-card" class="card hidden">
            <div class="card-label">Meeting point</div>
            <div class="meta-row" style="border-top:none; padding-top:0;">
                <span id="meeting-name" class="meta-value"></span>
            </div>
        </div>

        <div class="footer-note">
            @if($expiresAt)
            This link stays active until {{ $expiresAt->format('M j, g:i A') }}.<br>
            @endif
            Shared privately by a traveler using Hidden Gems SL. This page does not require an account.
        </div>
    </div>

    <script>
        (function () {
            var PHASE_LABELS = {
                assembling: 'Getting ready to depart',
                en_route: 'On the move',
                at_site: 'At the destination',
                break_time: 'Taking a break',
                returning: 'Heading back',
                completed: 'Tour finished'
            };

            function show(id) { document.getElementById(id).classList.remove('hidden'); }
            function hide(id) { document.getElementById(id).classList.add('hidden'); }
            function setText(id, text) { document.getElementById(id).textContent = text; }

            function base64UrlToBytes(b64url) {
                var b64 = b64url.replace(/-/g, '+').replace(/_/g, '/');
                while (b64.length % 4) b64 += '=';
                return base64ToBytes(b64);
            }

            function base64ToBytes(b64) {
                var bin = atob(b64);
                var bytes = new Uint8Array(bin.length);
                for (var i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
                return bytes;
            }

            function render(json) {
                if (typeof json.sosActive === 'boolean') {
                    if (json.sosActive) show('sos-banner'); else hide('sos-banner');
                }
                if (typeof json.phase === 'string') {
                    var label = PHASE_LABELS[json.phase] || 'Status unavailable';
                    document.getElementById('status-dot').classList.toggle('idle', json.phase === 'completed');
                    setText('status-text', label);
                    show('status-card');
                }
                if (typeof json.guideName === 'string' || json.guideName === null) {
                    setText('guide-name', json.guideName || 'Verified Hidden Gems SL guide');
                    show('guide-card');
                }
                if (typeof json.meetingPointName === 'string' && json.meetingPointName) {
                    setText('meeting-name', json.meetingPointName);
                    show('meeting-card');
                }
                hide('no-status-card');

                // SOS forces a faster refresh than the default 30s meta tag.
                // Reload preserves the URL (including the #k= fragment) since
                // this is a normal same-URL navigation, not a server redirect.
                if (json.sosActive === true) {
                    setTimeout(function () { window.location.reload(); }, 15000);
                }
            }

            async function main() {
                var encrypted = document.body.dataset.encrypted;
                if (!encrypted) {
                    // Pre-migration link or a brand-new link with no status yet.
                    return;
                }

                var match = /[#&]k=([^&]+)/.exec(window.location.hash);
                if (!match) {
                    hide('no-status-card');
                    show('decrypt-error');
                    return;
                }

                var parts = encrypted.split(':');
                if (parts.length !== 2) {
                    hide('no-status-card');
                    show('decrypt-error');
                    return;
                }

                try {
                    var keyBytes = base64UrlToBytes(match[1]);
                    var iv = base64ToBytes(parts[0]);
                    var cipherBytes = base64ToBytes(parts[1]);

                    var key = await window.crypto.subtle.importKey(
                        'raw', keyBytes, { name: 'AES-GCM' }, false, ['decrypt']
                    );
                    var plainBuf = await window.crypto.subtle.decrypt(
                        { name: 'AES-GCM', iv: iv }, key, cipherBytes
                    );
                    var json = JSON.parse(new TextDecoder().decode(plainBuf));
                    render(json);
                } catch (e) {
                    hide('no-status-card');
                    show('decrypt-error');
                }
            }

            main();
        })();
    </script>
</body>
</html>
