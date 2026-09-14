import os

special_chars = {
    '\u00b0': r'\u00B0',  # degree sign °
    '\u00b7': r'\u00B7',  # middle dot ·
    '\u2014': r'\u2014',  # em dash —
    '\u2013': r'\u2013',  # en dash –
    '\u2022': r'\u2022',  # bullet •
    '\u201c': r'\u201C',  # left double quote “
    '\u201d': r'\u201D',  # right double quote ”
}

targets = ['lib', 'laravel-backend/resources/views']
occurrences = []

for target in targets:
    for root, dirs, files in os.walk(target):
        for f in files:
            if f.endswith(('.dart', '.blade.php')):
                path = os.path.join(root, f)
                with open(path, 'r', encoding='utf-8', errors='replace') as fp:
                    for idx, line in enumerate(fp, 1):
                        # check if any special char is in line
                        for ch in special_chars:
                            if ch in line:
                                occurrences.append((path, idx, ch, line.strip()))
                                break

print(f"Total lines with special characters: {len(occurrences)}")
for o in occurrences[:40]:
    safe = o[3][:90].encode('ascii', errors='backslashreplace').decode('ascii')
    print(f"{o[0]}:{o[1]} [{special_chars.get(o[2], '?')}]: {safe}")
