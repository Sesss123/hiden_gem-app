@php
    $sosActive = ($permissions['show_emergency'] ?? false) && ($session['sosActive'] ?? false);
    $phase = $session['currentPhase'] ?? null;
    $phaseLabels = [
        'assembling' => 'Getting ready to depart',
        'en_route' => 'On the move',
        'at_site' => 'At the destination',
        'break_time' => 'Taking a break',
        'returning' => 'Heading back',
        'completed' => 'Tour finished',
    ];
    $phaseLabel = $phaseLabels[$phase] ?? 'Status unavailable';
    $recipientName = $link['recipientName'] ?? 'there';
    $expiresAt = isset($link['expiresAt']) ? \Carbon\Carbon::parse($link['expiresAt']) : null;
@endphp
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    @if(!$sosActive)
    <meta http-equiv="refresh" content="30">
    @else
    <meta http-equiv="refresh" content="15">
    @endif
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
    </style>
</head>
<body>
    <div class="wrap">
        <div class="eyebrow">Hidden Gems SL &middot; Live trip sharing</div>
        <h1>Hi {{ $recipientName }}, here's the latest</h1>

        @if($sosActive)
        <div class="sos-banner">
            <span class="dot"></span>
            <span>Emergency alert active — the traveler has triggered SOS. This page refreshes automatically.</span>
        </div>
        @endif

        @if(!$session)
        <div class="card">
            <div class="card-label">Status</div>
            <div class="locked-card">No tour session linked to this trip yet.</div>
        </div>
        @else
            @if($permissions['show_status'] ?? false)
            <div class="card">
                <div class="card-label">Current status</div>
                <div class="status-row">
                    <span class="status-dot {{ $phase === 'completed' ? 'idle' : '' }}"></span>
                    <span class="status-text">{{ $phaseLabel }}</span>
                </div>
            </div>
            @endif

            @if($permissions['show_identity'] ?? false)
            <div class="card">
                <div class="card-label">Guide</div>
                <div class="meta-row" style="border-top:none; padding-top:0;">
                    <span class="meta-value">{{ $guideName ?? 'Verified Hidden Gems SL guide' }}</span>
                </div>
            </div>
            @endif

            @if(($permissions['show_meeting_point'] ?? false) && !empty($session['meetingPointName']))
            <div class="card">
                <div class="card-label">Meeting point</div>
                <div class="meta-row" style="border-top:none; padding-top:0;">
                    <span class="meta-value">{{ $session['meetingPointName'] }}</span>
                </div>
            </div>
            @endif
        @endif

        <div class="footer-note">
            @if($expiresAt)
            This link stays active until {{ $expiresAt->format('M j, g:i A') }}.<br>
            @endif
            Shared privately by a traveler using Hidden Gems SL. This page does not require an account.
        </div>
    </div>
</body>
</html>
