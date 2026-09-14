import 'package:flutter/widgets.dart';

class TravelerSafetyCopy {
  const TravelerSafetyCopy._();

  static String _language(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  static String sosComposerOpened(BuildContext context) => switch (_language(context)) {
        'si' => 'දුරකථන/SMS app එක විවෘත කළා. ඇමතුම සම්පූර්ණ කරන්න හෝ Send ඔබන්න; හදිසි සේවා ස්වයංක්‍රීයව සම්බන්ධ නොවේ.',
        'ta' => 'தொலைபேசி/SMS செயலி திறக்கப்பட்டது. அழைப்பை முடிக்கவும் அல்லது Send அழுத்தவும்; அவசர சேவைகள் தானாக தொடர்புகொள்ளப்படாது.',
        'ja' => '電話／SMSアプリを開きました。通話を完了するか送信を押してください。緊急機関へ自動送信はされません。',
        'ko' => '전화/SMS 앱을 열었습니다. 통화를 완료하거나 전송을 누르세요. 긴급 서비스에 자동으로 연락되지는 않습니다.',
        'ru' => 'Открыто приложение телефона/SMS. Завершите звонок или нажмите «Отправить»; экстренные службы не вызываются автоматически.',
        _ => 'Phone/SMS app opened. Complete the call or tap Send; emergency services are not contacted automatically.',
      };

  static String hubDisclosure(BuildContext context) => switch (_language(context)) {
        'si' => 'Guide/admin hub එකට alert කරයි. පොලිසිය ස්වයංක්‍රීයව සම්බන්ධ නොවේ—අවශ්‍ය නම් 119 හෝ 1990 අමතන්න.',
        'ta' => 'வழிகாட்டி/நிர்வாக மையத்திற்கு எச்சரிக்கை அனுப்பும். காவல்துறை தானாக தொடர்புகொள்ளப்படாது; 119 அல்லது 1990 ஐ அழைக்கவும்.',
        'ja' => 'ガイド／管理ハブへ通知します。警察には自動連絡されません。必要なら119または1990へ電話してください。',
        'ko' => '가이드/관리 허브에 알립니다. 경찰에 자동으로 연락되지는 않습니다. 필요하면 119 또는 1990으로 전화하세요.',
        'ru' => 'Оповещает гида/администратора в приложении. Полиция не вызывается автоматически; звоните 119 или 1990.',
        _ => 'Alerts your guide/admin hub. Police are not contacted automatically—call 119 or 1990 if needed.',
      };

  static String hubShared(BuildContext context) => switch (_language(context)) {
        'si' => 'SOS එක app guide/admin hub එකට යවා ඇත. හදිසි සේවයට 119 හෝ 1990 අමතන්න.',
        'ta' => 'SOS செயலியின் வழிகாட்டி/நிர்வாக மையத்துடன் பகிரப்பட்டது. 119 அல்லது 1990 ஐ அழைக்கவும்.',
        'ja' => 'SOSをアプリ内のガイド／管理ハブへ共有しました。119または1990へ電話してください。',
        'ko' => 'SOS가 앱 내 가이드/관리 허브에 공유되었습니다. 119 또는 1990으로 전화하세요.',
        'ru' => 'SOS передан гиду/администратору в приложении. Звоните 119 или 1990.',
        _ => 'SOS shared with the in-app guide/admin hub. Call 119 or 1990 for emergency services.',
      };

  static String offlinePreviewSaved(BuildContext context) => switch (_language(context)) {
        'si' => 'Offline map preview එක save කළා. මෙය turn-by-turn navigation හෝ rerouting ලබා නොදේ.',
        'ta' => 'ஆஃப்லைன் வரைபட முன்னோட்டம் சேமிக்கப்பட்டது. வழிசெலுத்தல் அல்லது மறுவழி அமைத்தல் கிடையாது.',
        _ => 'Offline map preview saved. It does not provide turn-by-turn navigation or rerouting.',
      };

  static String offlinePreviewWarning(BuildContext context) => switch (_language(context)) {
        'si' => 'OFFLINE MAP PREVIEW • Live navigation, traffic හෝ rerouting නැත',
        'ta' => 'ஆஃப்லைன் வரைபட முன்னோட்டம் • நேரடி வழிசெலுத்தல் இல்லை',
        _ => 'OFFLINE MAP PREVIEW • No live navigation, traffic, or rerouting',
      };

  static String verifiedOn(BuildContext context, String date) =>
      switch (_language(context)) {
        'si' => '$date දින තහවුරු කර ඇත',
        'ta' => '$date அன்று சரிபார்க்கப்பட்டது',
        'ja' => '$date に確認済み',
        'ko' => '$date 확인됨',
        'ru' => 'Проверено $date',
        _ => 'Verified $date',
      };
}
