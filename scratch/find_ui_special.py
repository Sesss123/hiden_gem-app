import os
import re

ui_string_pattern = re.compile(r'["\']([^"\']*(?:[\u00b0\u00b7\u2014\u2013\u2022\u201c\u201d]|Â|â)[^"\']*)["\']')

results = []

targets = ['lib', 'laravel-backend/resources/views']

for target in targets:
    for root, dirs, files in os.walk(target):
        for f in files:
            if f.endswith(('.dart', '.blade.php')):
                path = os.path.join(root, f)
                with open(path, 'r', encoding='utf-8', errors='replace') as fp:
                    for idx, line in enumerate(fp, 1):
                        stripped = line.strip()
                        # Ignore comment lines
                        if stripped.startswith('//') or stripped.startswith('/*') or stripped.startswith('*') or stripped.startswith('///'):
                            continue
                        m = ui_string_pattern.search(line)
                        if m:
                            results.append((path, idx, m.group(1), line.strip()))

print(f"Total UI strings with non-ASCII / special chars: {len(results)}")
for r in results[:50]:
    safe = r[2][:60].encode('ascii', errors='backslashreplace').decode('ascii')
    print(f"{r[0]}:{r[1]} -> {safe}")
