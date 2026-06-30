import 'dart:convert';
import 'dart:io';

void main() {
  final enFile = File('lib/l10n/app_en.arb');
  final enMap = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
  
  final langs = ['ta', 'ja', 'ko', 'ru'];
  for (var lang in langs) {
    final file = File('lib/l10n/app_$lang.arb');
    if (!file.existsSync()) continue;
    
    final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    
    // Add missing keys
    for (var key in enMap.keys) {
      if (!map.containsKey(key)) {
        map[key] = enMap[key];
      }
    }
    
    // Write back properly formatted
    file.writeAsStringSync(JsonEncoder.withIndent('  ').convert(map));
    stdout.writeln('Synced app_$lang.arb');
  }
}
