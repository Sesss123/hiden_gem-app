import json

family_titles = {
    'en': "Family Share",
    'si': "පවුලේ බෙදාගැනීම",
    'ta': "குடும்ப பகிர்வு",
    'ja': "ファミリー共有",
    'ko': "가족 공유",
    'ru': "Семейный доступ"
}

for lang, title in family_titles.items():
    file_path = f'lib/l10n/app_{lang}.arb'
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    data['familyShareTitle'] = title
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Added familyShareTitle to {file_path}")
