<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Link unavailable — Hidden Gems SL</title>
    <style>
        :root {
            --rust: #C1440E;
            --earth: #6B4226;
            --bg: #FFFDF8;
            --ink: #2B211B;
            --muted: #8A7B6C;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: var(--bg);
            color: var(--ink);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            padding: 24px;
        }
        .card {
            max-width: 380px;
            text-align: center;
        }
        .icon {
            width: 56px; height: 56px;
            margin: 0 auto 20px;
            border-radius: 16px;
            background: rgba(193, 68, 14, 0.1);
            display: flex; align-items: center; justify-content: center;
            font-size: 26px;
        }
        h1 { font-size: 20px; margin: 0 0 8px; }
        p { color: var(--muted); font-size: 14px; line-height: 1.6; margin: 0; }
    </style>
</head>
<body>
    <div class="card">
        <div class="icon">🔗</div>
        <h1>{{ $reason === 'not_found' ? 'Link not found' : 'This link has expired' }}</h1>
        <p>
            @if($reason === 'not_found')
                This tracking link doesn't exist or has already been removed by the traveler.
            @else
                The traveler's sharing window has ended. Ask them to generate a new link from the Hidden Gems SL app if you still need to track their trip.
            @endif
        </p>
    </div>
</body>
</html>
