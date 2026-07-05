import re

try:
    with open('analyze_output.txt', 'r', encoding='utf-16') as f:
        lines = f.read().splitlines()
except:
    with open('analyze_output.txt', 'r', encoding='utf-8') as f:
        lines = f.read().splitlines()

errors = [l for l in lines if 'const_eval_property_access' in l or 'invalid_constant' in l]

changes = {}
for e in errors:
    # Example: error - Invalid constant value - lib\presentation\screens\review_submission_screen.dart:109:56 - invalid_constant
    # Example: error - The property 'white' can't be accessed... - lib\presentation\screens\results_screen.dart:312:32 - const_eval_property_access
    match = re.search(r'- (lib\\[^:]+\.dart):(\d+):\d+', e)
    if not match:
        match = re.search(r'- (lib/[^:]+\.dart):(\d+):\d+', e)
    if match:
        filepath = match.group(1).replace('\\', '/')
        line_num = int(match.group(2)) - 1 # 0-indexed
        
        if filepath not in changes:
            changes[filepath] = []
        changes[filepath].append(line_num)

for filepath, line_nums in changes.items():
    print(f"Fixing {filepath} ({len(line_nums)} lines)")
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read().splitlines()
        
        for ln in set(line_nums):
            if ln < len(content):
                line = content[ln]
                # Try to remove `const ` safely
                new_line = re.sub(r'\bconst\s+', '', line)
                content[ln] = new_line
                
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write('\n'.join(content) + '\n')
    except Exception as ex:
        print(f"Error processing {filepath}: {ex}")

