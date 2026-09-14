import json

keys_by_lang = {
    'en': {
        "sosDispatchMessage": "EMERGENCY: I need help. My current location is: {mapUrl} (Sent via Hidden Gems SL)",
        "@sosDispatchMessage": {
            "placeholders": { "mapUrl": { "type": "String" } }
        },
        "sosFailedAppLaunch": "Could not open the phone or SMS app. Call 119 or 1990 now.",
        "weatherConditionClear": "Clear Sky",
        "weatherConditionClouds": "Cloudy",
        "weatherConditionRain": "Rain",
        "weatherConditionThunderstorm": "Thunderstorm",
        "weatherConditionDrizzle": "Drizzle",
        "weatherConditionMist": "Mist / Fog",
        "rainSafetyAdvisory": "Rain / Thunderstorm Alert: Carry an umbrella and exercise caution on winding roads.",
        "moreToolsTitle": "More Tools & Experiences",
        "moreToolsSubtitle": "Food AI, AR Portals, Oracle, Passport & Budget",
        "savedPlacesHubTitle": "Saved Places & Wishlist",
        "savedPlacesHubSubtitle": "Bookmarks, Want to Visit & History",
        "mapActionLabel": "Map",
        "safetyActionLabel": "Safety",
        "foodScannerTooltip": "Food scanner"
    },
    'si': {
        "sosDispatchMessage": "හදිසි අවස්ථාවකි: මට උදව් අවශ්‍යයි. මගේ වත්මන් ස්ථානය: {mapUrl} (Hidden Gems SL මඟින් එවන ලදී)",
        "sosFailedAppLaunch": "දුරකථන හෝ SMS යෙදුම විවෘත කළ නොහැකි විය. කරුණාකර දැන්ම 119 හෝ 1990 අමතන්න.",
        "weatherConditionClear": "පැහැදිලි අහස",
        "weatherConditionClouds": "වලාකුළු සහිතයි",
        "weatherConditionRain": "වැසි සහිතයි",
        "weatherConditionThunderstorm": "ගිගුරුම් සහිත වැසි",
        "weatherConditionDrizzle": "පොද වැසි",
        "weatherConditionMist": "මීදුම සහිතයි",
        "rainSafetyAdvisory": "වැසි / ගිගුරුම් අනතුරු ඇඟවීම: කුඩයක් රැගෙන යන්න, කඳුකර වංගු සහිත මාර්ග වල ප්‍රවේශම් වන්න.",
        "moreToolsTitle": "තවත් මෙවලම් සහ විශේෂාංග",
        "moreToolsSubtitle": "Food AI, AR Portals, Oracle, Passport සහ Budget",
        "savedPlacesHubTitle": "සුරැකි ස්ථාන සහ ප්‍රාර්ථනා ලැයිස්තුව",
        "savedPlacesHubSubtitle": "පිටු සලකුණු, යාමට කැමති ස්ථාන සහ ඉතිහාසය",
        "mapActionLabel": "සිතියම",
        "safetyActionLabel": "ආරක්ෂාව",
        "foodScannerTooltip": "ආහාර ස්කෑනරය"
    },
    'ta': {
        "sosDispatchMessage": "அவசரம்: எனக்கு உதவி தேவை. எனது தற்போதைய இடம்: {mapUrl} (Hidden Gems SL மூலம் அனுப்பப்பட்டது)",
        "sosFailedAppLaunch": "தொலைபேசி அல்லது SMS செயலியை திறக்க முடியவில்லை. உடனடியாக 119 அல்லது 1990 ஐ அழைக்கவும்.",
        "weatherConditionClear": "தெளிவான வானம்",
        "weatherConditionClouds": "மேகமூட்டம்",
        "weatherConditionRain": "மழை",
        "weatherConditionThunderstorm": "இடியுடன் கூடிய மழை",
        "weatherConditionDrizzle": "தூறல்",
        "weatherConditionMist": "பனிமூட்டம்",
        "rainSafetyAdvisory": "மழை / இடியுடன் கூடிய மழை எச்சரிக்கை: குடை எடுத்துச் செல்லவும், வளைந்த சாலைகளில் எச்சரிக்கையாக இருக்கவும்.",
        "moreToolsTitle": "கூடுதல் கருவிகள் & அனுபவங்கள்",
        "moreToolsSubtitle": "உணவு AI, AR, தரவுத்தளம் & பட்ஜெட்",
        "savedPlacesHubTitle": "சேமிக்கப்பட்ட இடங்கள் & விருப்பப்பட்டியல்",
        "savedPlacesHubSubtitle": "புக்மார்க்குகள், பார்க்க விரும்புபவை & வரலாறு",
        "mapActionLabel": "வரைபடம்",
        "safetyActionLabel": "பாதுகாப்பு",
        "foodScannerTooltip": "உணவு ஸ்கேனர்"
    },
    'ja': {
        "sosDispatchMessage": "緊急事態：助けが必要です。私の現在地：{mapUrl} (Hidden Gems SLより送信)",
        "sosFailedAppLaunch": "電話またはSMSアプリを開けませんでした。今すぐ 119 または 1990 に電話してください。",
        "weatherConditionClear": "快晴",
        "weatherConditionClouds": "曇り",
        "weatherConditionRain": "雨",
        "weatherConditionThunderstorm": "雷雨",
        "weatherConditionDrizzle": "霧雨",
        "weatherConditionMist": "霧",
        "rainSafetyAdvisory": "大雨・雷雨注意報：傘を携帯し、曲がりくねった山道では運転・歩行にご注意ください。",
        "moreToolsTitle": "その他のツールと体験",
        "moreToolsSubtitle": "グルメAI、ARポータル、オラクル、パスポート、予算管理",
        "savedPlacesHubTitle": "保存した場所と行きたい場所",
        "savedPlacesHubSubtitle": "ブックマーク、訪問希望、閲覧履歴",
        "mapActionLabel": "マップ",
        "safetyActionLabel": "安全",
        "foodScannerTooltip": "フードスキャナー"
    },
    'ko': {
        "sosDispatchMessage": "긴급 상황: 도움이 필요합니다. 저의 현재 위치: {mapUrl} (Hidden Gems SL을 통해 전송됨)",
        "sosFailedAppLaunch": "전화 또는 SMS 앱을 열 수 없습니다. 지금 119 또는 1990으로 전화하십시오.",
        "weatherConditionClear": "맑음",
        "weatherConditionClouds": "구름 많음",
        "weatherConditionRain": "비",
        "weatherConditionThunderstorm": "뇌우",
        "weatherConditionDrizzle": "이슬비",
        "weatherConditionMist": "안개",
        "rainSafetyAdvisory": "호우/뇌우 주의보: 우산을 지참하고 굽은 도로에서 서행하십시오.",
        "moreToolsTitle": "추가 도구 및 경험",
        "moreToolsSubtitle": "음식 AI, AR 포털, 오라클, 패스포트 및 예산 관리",
        "savedPlacesHubTitle": "저장된 장소 및 위시리스트",
        "savedPlacesHubSubtitle": "북마크, 가고 싶은 곳 및 방문 기록",
        "mapActionLabel": "지도",
        "safetyActionLabel": "안전",
        "foodScannerTooltip": "음식 스캐너"
    },
    'ru': {
        "sosDispatchMessage": "ЭКСТРЕННАЯ СИТУАЦИЯ: Мне нужна помощь. Мое местоположение: {mapUrl} (Отправлено через Hidden Gems SL)",
        "sosFailedAppLaunch": "Не удалось открыть приложение телефона или SMS. Позвоните 119 или 1990 прямо сейчас.",
        "weatherConditionClear": "Ясно",
        "weatherConditionClouds": "Облачно",
        "weatherConditionRain": "Дождь",
        "weatherConditionThunderstorm": "Гроза",
        "weatherConditionDrizzle": "Морось",
        "weatherConditionMist": "Туман",
        "rainSafetyAdvisory": "Предупреждение о дожде и грозе: возьмите зонт и соблюдайте осторожность на извилистых дорогах.",
        "moreToolsTitle": "Дополнительные инструменты",
        "moreToolsSubtitle": "Food AI, AR, Оракул, Паспорт и Бюджет",
        "savedPlacesHubTitle": "Сохраненные места и список желаний",
        "savedPlacesHubSubtitle": "Закладки, хочу посетить и история",
        "mapActionLabel": "Карта",
        "safetyActionLabel": "Безопасность",
        "foodScannerTooltip": "Сканер еды"
    }
}

for lang, new_keys in keys_by_lang.items():
    file_path = f'lib/l10n/app_{lang}.arb'
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    data.update(new_keys)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Updated {file_path}")
