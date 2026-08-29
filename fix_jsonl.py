import json
import re

def fix_jsonl(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check if it's already a valid json array
        try:
            data = json.loads(content)
            if isinstance(data, list):
                # Write back as jsonl
                with open(filepath, 'w', encoding='utf-8') as f:
                    for item in data:
                        f.write(json.dumps(item) + '\n')
                print(f"Fixed {filepath} from JSON array to JSONL")
                return
        except json.JSONDecodeError:
            pass
        
        # If not, let's try to extract all json objects
        # We find all content between { and } at the top level
        # Actually, simpler: just remove any leading [ and trailing ]
        # and then split by "}\n{" or something similar, or just parse multiple json objects
        
        # A robust way is to use a regex to find all { ... } blocks if they are not nested too crazily
        # But wait, json.loads has json.JSONDecoder().raw_decode
        decoder = json.JSONDecoder()
        pos = 0
        objects = []
        
        # Clean up some common syntax errors
        content = content.strip()
        if content.startswith('['):
            content = content[1:]
        if content.endswith(']'):
            content = content[:-1]
        
        content = content.strip()
        
        while pos < len(content):
            # Skip whitespace and commas
            match = re.match(r'[\s,]+', content[pos:])
            if match:
                pos += match.end()
            if pos >= len(content):
                break
                
            try:
                obj, new_pos = decoder.raw_decode(content[pos:])
                objects.append(obj)
                pos += new_pos
            except json.JSONDecodeError as e:
                print(f"Error decoding at pos {pos} in {filepath}: {e}")
                # Try to advance past the error or it might fail completely
                break
                
        if objects:
            with open(filepath, 'w', encoding='utf-8') as f:
                for item in objects:
                    f.write(json.dumps(item) + '\n')
            print(f"Fixed {filepath} by extracting {len(objects)} objects into JSONL")
        else:
            print(f"Could not parse any objects from {filepath}")

    except Exception as e:
        print(f"Failed to process {filepath}: {e}")

files = [
    r"d:\app ai\data\raw\Ampara\religious_places.jsonl",
    r"d:\app ai\data\raw\Ampara\waterfalls.jsonl",
    r"d:\app ai\data\raw\Ampara\tea_estate.jsonl"
]

for f in files:
    fix_jsonl(f)
