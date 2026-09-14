import os
import re

patterns = [
    (re.compile(r'\xc2[\x80-\xbf]'), 'Latin-1 byte encoded as UTF-8 (e.g. Â°, Â·)'),
    (re.compile(r'\xe2\x80[\x90-\xbf]'), 'UTF-8 Windows-1252 punctuation artifact (e.g. â€”, â€“)'),
    (re.compile(r'\xc3[\x80-\xbf]'), 'UTF-8 Latin extended artifact'),
    (re.compile(r'ðŸ'), 'Emoji mojibake (ðŸ...)'),
    (re.compile(r'â\s*³'), 'Hourglass mojibake'),
    (re.compile(r'Â'), 'Stray Â'),
]

results = []

# target folders
targets = ['lib', 'laravel-backend']

for target in targets:
    for root, dirs, files in os.walk(target):
        if any(skip in root for skip in ['.git', 'vendor', 'node_modules', '.dart_tool', 'build', 'storage']):
            continue
        for f in files:
            if f.endswith(('.dart', '.blade.php', '.php', '.arb', '.json', '.html')):
                filepath = os.path.join(root, f)
                try:
                    with open(filepath, 'rb') as fp:
                        raw = fp.read()
                    
                    # Also check if decoding as utf-8 fails or if text contains literal Â or â€
                    text = raw.decode('utf-8', errors='replace')
                    
                    lines = text.splitlines()
                    for line_no, line in enumerate(lines, 1):
                        # check for literal mojibake patterns
                        if 'Â' in line or 'â€' in line or 'ðŸ' in line or 'â ³' in line:
                            results.append((filepath, line_no, line.strip()))
                except Exception as e:
                    results.append((filepath, 0, f"Error: {e}"))

print(f"Total mojibake lines found: {len(results)}")
for r in results:
    safe_line = r[2][:100].encode('ascii', errors='backslashreplace').decode('ascii')
    print(f"{r[0]}:{r[1]}: {safe_line}")
