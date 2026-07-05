import re

with open('lib/core/theme/app_theme.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace AppPalette
content = re.sub(r'static const Color bg = AppTheme\.colors\.primary;', r'static const Color bg = Color(0xFFF9F6F0);', content)
content = re.sub(r'static const Color bg2 = AppTheme\.colors\.primary;', r'static const Color bg2 = Color(0xFFF2EBE1);', content)
content = re.sub(r'static const Color surface = AppTheme\.colors\.primary;', r'static const Color surface = Color(0xFFFFFFFF);', content)
content = re.sub(r'static const Color rust = AppTheme\.colors\.primary;', r'static const Color rust = Color(0xFFB54933);', content)
content = re.sub(r'static const Color rustDim = AppTheme\.colors\.primary;', r'static const Color rustDim = Color(0xFFD67360);', content)
content = re.sub(r'static const Color heroCream = AppTheme\.colors\.primary;', r'static const Color heroCream = Color(0xFFF5E6CC);', content)
content = re.sub(r'static const Color heroOchre = AppTheme\.colors\.primary;', r'static const Color heroOchre = Color(0xFFD39E4C);', content)
content = re.sub(r'static const Color earth = AppTheme\.colors\.primary;', r'static const Color earth = Color(0xFF4C5B4E);', content)
content = re.sub(r'static const Color sand = AppTheme\.colors\.primary;', r'static const Color sand = Color(0xFFDABF99);', content)
content = re.sub(r'static const Color sand2 = AppTheme\.colors\.primary;', r'static const Color sand2 = Color(0xFFC7A87A);', content)
content = re.sub(r'static const Color ink = AppTheme\.colors\.primary;', r'static const Color ink = Color(0xFF232B25);', content)
content = re.sub(r'static const Color success = AppTheme\.colors\.primary;', r'static const Color success = Color(0xFF2E7D32);', content)
content = re.sub(r'static const Color error = AppTheme\.colors\.primary;', r'static const Color error = Color(0xFFC62828);', content)
content = re.sub(r'static const Color warning = AppTheme\.colors\.primary;', r'static const Color warning = Color(0xFFF57F17);', content)

# Replace AppPaletteDark
content = re.sub(r'static const Color card = AppTheme\.colors\.primary;', r'static const Color card = Color(0xFF1E2420);', content)
content = re.sub(r'static const Color gem = AppTheme\.colors\.primary;', r'static const Color gem = Color(0xFF0277BD);', content)
content = re.sub(r'static const Color gemDim = AppTheme\.colors\.primary;', r'static const Color gemDim = Color(0xFF039BE5);', content)
content = re.sub(r'static const Color gold = AppTheme\.colors\.primary;', r'static const Color gold = Color(0xFFFFB300);', content)
content = re.sub(r'static const Color blue = AppTheme\.colors\.primary;', r'static const Color blue = Color(0xFF1565C0);', content)
content = re.sub(r'static const Color text = AppTheme\.colors\.primary;', r'static const Color text = Color(0xFFF8FAFC);', content)
content = re.sub(r'static const Color textSub = AppTheme\.colors\.primary;', r'static const Color textSub = Color(0xFFA0AAB2);', content)

with open('lib/core/theme/app_theme.dart', 'w', encoding='utf-8') as f:
    f.write(content)
