import os
import re

files = [
    'lib/presentation/screens/real_time_food_scanner_screen.dart',
    'lib/presentation/screens/profile_screen.dart',
    'lib/presentation/screens/savor_lanka_screen.dart',
    'lib/data/repositories/tour_session_repository.dart',
    'lib/data/datasources/trip_cache_service.dart',
    'lib/data/datasources/user_preference_service.dart',
    'lib/core/services/voice_recipe_service.dart',
    'lib/core/services/delta_sync_service.dart',
    'lib/core/services/sqlite_storage_service.dart'
]

for file in files:
    path = os.path.join(r'c:\Users\sehas\.gemini\antigravity\scratch\hidden_gems_sl', file)
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Replace 'catch (_) {}' with proper logging
        content = re.sub(r'catch\s*\(\_\)\s*\{\s*\}', r'catch (e, st) { SecureLogger.warning("Exception caught", e, st); }', content)
        
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
