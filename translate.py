import urllib.request
import urllib.parse
import json
import time
import re

def translate_text(text, target_lang):
    if not text.strip(): return text
    
    # Don't translate placeholders like {era}
    placeholders = re.findall(r'\{.*?\}', text)
    temp_text = text
    for i, p in enumerate(placeholders):
        temp_text = temp_text.replace(p, f'__PH{i}__')
        
    url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=" + target_lang + "&dt=t&q=" + urllib.parse.quote(temp_text)
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req) as response:
            res = json.loads(response.read().decode('utf-8'))
            translated = "".join([part[0] for part in res[0]])
            
            for i, p in enumerate(placeholders):
                translated = translated.replace(f'__PH{i}__', p)
                
            return translated
    except Exception as e:
        print(f"Failed to translate: {text} to {target_lang}")
        return text

# load en
with open('lib/l10n/app_en.arb', 'r', encoding='utf-8') as f:
    en_data = json.load(f)

for lang, filename in [('ta', 'app_ta.arb'), ('ja', 'app_ja.arb'), ('ko', 'app_ko.arb'), ('ru', 'app_ru.arb')]:
    print(f"Translating to {lang}...")
    with open('lib/l10n/' + filename, 'r', encoding='utf-8') as f:
        target_data = json.load(f)
    
    # ensure all keys from en are in target
    for key, val in en_data.items():
        if key.startswith('@'):
            target_data[key] = val
            continue
            
        if key == 'appTitle':
            target_data[key] = 'Hidden Gems SL'
            continue
            
        if key == 'picksForYou':
            target_data[key] = translate_text('Hidden Gems SL Picks for you', lang)
            continue
            
        # translate if missing or if it's the exact same as english (which means it's untranslated)
        # Note: some keys might be legitimately same as english in other languages, but for our app, probably not many.
        # Let's just translate if they are equal to english val or missing.
        if key not in target_data or target_data[key] == val:
            print(f"Translating key: {key}")
            target_data[key] = translate_text(val, lang)
            time.sleep(0.5) # limit rate to avoid 429
            
    with open('lib/l10n/' + filename, 'w', encoding='utf-8') as f:
        json.dump(target_data, f, ensure_ascii=False, indent=2)
