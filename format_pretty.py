import json
import glob
import re
import os

def format_as_pretty_json(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read().strip()
            
        if not content:
            return

        # Attempt to decode as JSON array
        try:
            data = json.loads(content)
            if not isinstance(data, list):
                data = [data] # wrap in list if single object
        except json.JSONDecodeError:
            # Maybe it's jsonl or missing commas
            # Let's fix missing commas
            content = re.sub(r'\}\s*\{', '},{', content)
            
            if content.startswith('{') and content.endswith('}'):
                content = '[' + content + ']'
                
            if not content.startswith('['):
                content = '[' + content + ']'
                
            try:
                data = json.loads(content)
            except json.JSONDecodeError as e:
                # Use raw decode for fallback
                decoder = json.JSONDecoder()
                pos = 0
                data = []
                # Clean brackets if any
                if content.startswith('['): content = content[1:]
                if content.endswith(']'): content = content[:-1]
                content = content.strip()
                
                while pos < len(content):
                    match = re.match(r'[\s,]+', content[pos:])
                    if match:
                        pos += match.end()
                    if pos >= len(content):
                        break
                    try:
                        obj, new_pos = decoder.raw_decode(content[pos:])
                        data.append(obj)
                        pos += new_pos
                    except json.JSONDecodeError as e:
                        print(f"Fallback parsing error in {filepath}: {e}")
                        break

        # Now write it back pretty printed
        if data:
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=4, ensure_ascii=False)
            print(f"Formatted {filepath} as pretty JSON array")
            
    except Exception as e:
        print(f"Failed to process {filepath}: {e}")

files = [
    r"d:\app ai\data\raw\Ampara\osm_viewpoint.jsonl",
    r"d:\app ai\data\raw\Ampara\waterfalls.jsonl",
    r"d:\app ai\data\raw\Ampara\religious_places.jsonl",
    r"d:\app ai\data\raw\Ampara\tea_estate.jsonl"
]

for f in files:
    if os.path.exists(f):
        format_as_pretty_json(f)
