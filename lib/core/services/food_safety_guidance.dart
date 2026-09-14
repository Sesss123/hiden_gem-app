import 'package:flutter/widgets.dart';

/// Short, non-medical food-safety guidance shown alongside scan/place advice.
/// Copy is deliberately conservative and falls back to English when a locale
/// is not one of the supported traveller languages.
class FoodSafetyGuidance {
  FoodSafetyGuidance._();

  static List<String> tips(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    return _tips[language] ?? _tips['en']!;
  }

  static const Map<String, List<String>> _tips = {
    'en': [
      'Choose food cooked hot and served fresh; avoid food sitting uncovered.',
      'For seafood, choose a busy vendor and food that smells fresh and is fully cooked.',
      'Prefer factory-made tube ice; avoid unknown crushed or block ice.',
      'Start with mild spice if unfamiliar. Drink safe water and seek help for persistent symptoms.',
      'For dehydration, ask a pharmacy about oral rehydration salts (Jeewani/ORS).',
    ],
    'si': [
      'උණුසුම්ව නැවුම්ව පිසූ ආහාර තෝරන්න; ආවරණය නොකළ ආහාර වලින් වළකින්න.',
      'මුහුදු ආහාර සඳහා නැවුම් සුවඳ ඇති, සම්පූර්ණයෙන් පිසූ ආහාර තෝරන්න.',
      'කර්මාන්තශාලා නිෂ්පාදිත සිලින්ඩරාකාර අයිස් තෝරන්න; නොදන්නා අයිස් වලින් වළකින්න.',
      'නොහුරු නම් අඩු සැරින් ආරම්භ කරන්න. විජලනයට ෆාමසියකින් ජීවනී/ORS විමසන්න.',
    ],
    'ta': [
      'சூடாகவும் புதிதாகவும் சமைத்த உணவைத் தேர்ந்தெடுக்கவும்; மூடப்படாத உணவைத் தவிர்க்கவும்.',
      'புதிய மணம் கொண்ட, நன்றாக வேகவைத்த கடல் உணவைத் தேர்ந்தெடுக்கவும்.',
      'தொழிற்சாலை தயாரித்த குழாய் வடிவ பனியைத் தேர்ந்தெடுக்கவும்.',
      'பழக்கமில்லையெனில் குறைந்த காரத்தில் தொடங்குங்கள்; நீரிழப்புக்கு ORS கேளுங்கள்.',
    ],
    'ja': [
      '熱々で作りたての料理を選び、覆いのない料理は避けてください。',
      '新鮮な香りがあり、十分に加熱された魚介類を選んでください。',
      '工場製の筒状アイスを選び、出所不明の氷は避けてください。',
      '慣れない場合は辛さを控え、脱水時は薬局でORSを相談してください。',
    ],
    'ko': [
      '뜨겁고 갓 조리된 음식을 선택하고 덮개 없는 음식은 피하세요.',
      '신선한 냄새가 나고 완전히 익힌 해산물을 선택하세요.',
      '공장에서 만든 원통형 얼음을 선택하고 출처가 불분명한 얼음은 피하세요.',
      '익숙하지 않다면 순한 맛부터 시작하고 탈수 시 약국에서 ORS를 문의하세요.',
    ],
    'ru': [
      'Выбирайте горячую свежеприготовленную еду; избегайте открытой еды.',
      'Выбирайте свежие морепродукты, полностью приготовленные и без неприятного запаха.',
      'Используйте фабричный трубчатый лёд; избегайте льда неизвестного происхождения.',
      'Начинайте с умеренной остроты; при обезвоживании спросите в аптеке про ОРС.',
    ],
  };
}
