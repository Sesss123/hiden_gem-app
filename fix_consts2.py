import re

errors = r"""
  error - The property 'white' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\main.dart:751:34 - const_eval_property_access
  error - The property 'green' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\ar_fallback_screen.dart:205:60 - const_eval_property_access
  error - The property 'primary' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\ar_fallback_screen.dart:352:56 - const_eval_property_access
  error - The property 'green' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\ar_viewer_screen.dart:312:36 - const_eval_property_access
  error - The property 'black87' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\ar_viewer_screen.dart:902:20 - const_eval_property_access
  error - The property 'white' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\ar_viewer_screen.dart:925:22 - const_eval_property_access
  error - The property 'white54' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\ar_viewer_screen.dart:1056:26 - const_eval_property_access
  error - The property 'white' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\ar_viewer_screen.dart:1579:71 - const_eval_property_access
  error - The property 'amberAccent' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\discovery_screen.dart:482:45 - const_eval_property_access
  error - The property 'white24' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\discovery_screen.dart:843:83 - const_eval_property_access
  error - The property 'white24' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\discovery_screen.dart:1047:87 - const_eval_property_access
  error - The property 'white24' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\discovery_screen.dart:1240:77 - const_eval_property_access
  error - The property 'white24' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\emergency_kit_screen.dart:497:49 - const_eval_property_access
  error - The property 'redAccent' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\family_share_screen.dart:122:26 - const_eval_property_access
  error - The property 'amber' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\guide_availability_screen.dart:102:22 - const_eval_property_access
  error - The property 'amber' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\guide_dashboard_screen.dart:422:54 - const_eval_property_access
  error - The property 'amber' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\guide_dashboard_screen.dart:427:62 - const_eval_property_access
  error - The property 'amber' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\guide_dashboard_screen.dart:432:59 - const_eval_property_access
  error - The property 'amber' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\guide_dashboard_screen.dart:437:53 - const_eval_property_access
  error - The property 'green' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\guide_earnings_screen.dart:414:36 - const_eval_property_access
  error - The property 'amber' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\guide_listing_editor_screen.dart:522:65 - const_eval_property_access
  error - The property 'primary' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\language_selection_screen.dart:44:32 - const_eval_property_access
  error - The property 'white' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\login_screen.dart:455:85 - const_eval_property_access
  error - The property 'amber' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\marketplace_results_screen.dart:282:69 - const_eval_property_access
  error - The property 'green' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\place_details_screen.dart:910:40 - const_eval_property_access
  error - The property 'red' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\profile_screen.dart:303:82 - const_eval_property_access
  error - The property 'greenAccent' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\profile_screen.dart:1016:32 - const_eval_property_access
  error - The property 'white' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\results_screen.dart:312:32 - const_eval_property_access
  error - The property 'primary' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\saved_plans_screen.dart:305:85 - const_eval_property_access
  error - The property 'white38' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\subscription_screen.dart:234:19 - const_eval_property_access
  error - The property 'white12' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\tourist_companion_hub.dart:333:69 - const_eval_property_access
  error - The property 'redAccent' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\screens\tourist_companion_hub.dart:675:28 - const_eval_property_access
  error - The property 'primary' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\widgets\batik_background.dart:18:26 - const_eval_property_access
  error - The property 'primary' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\widgets\batik_background.dart:23:26 - const_eval_property_access
  error - The property 'white' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\widgets\custom_buttons.dart:49:61 - const_eval_property_access
  error - The property 'white' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\widgets\custom_buttons.dart:64:30 - const_eval_property_access
  error - The property 'white' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\widgets\custom_buttons.dart:117:61 - const_eval_property_access
  error - The property 'white' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\widgets\custom_buttons.dart:125:26 - const_eval_property_access
  error - The property 'orange' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\widgets\marketplace_search_bar.dart:264:32 - const_eval_property_access
  error - The property 'white70' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\widgets\marketplace_search_bar.dart:303:18 - const_eval_property_access
  error - The property 'white' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\widgets\oracle_aura_widget.dart:94:26 - const_eval_property_access
  error - The property 'primary' can't be accessed on the type 'AppThemeColors' in a constant expression - lib\presentation\widgets\usage_meter_widget.dart:67:63 - const_eval_property_access
"""

changes = {}
for line in errors.strip().split('\n'):
    match = re.search(r'- (lib\\[^:]+\.dart):(\d+):\d+', line)
    if match:
        filepath = match.group(1).replace('\\', '/')
        line_num = int(match.group(2)) - 1
        if filepath not in changes:
            changes[filepath] = []
        changes[filepath].append(line_num)

for filepath, line_nums in changes.items():
    print(f"Fixing {filepath}")
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read().splitlines()
    
    for ln in set(line_nums):
        # Look backwards up to 5 lines to find 'const ' and remove the first occurrence
        for i in range(ln, max(-1, ln - 6), -1):
            if i < len(content) and 'const ' in content[i]:
                # We only want to remove `const ` if it's the start of a widget or something, but it's safe to just replace the first `const `
                content[i] = re.sub(r'\bconst\s+', '', content[i], count=1)
                break
                
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write('\n'.join(content) + '\n')
