import os
import re

def process_flutter(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    
    # 1. Colors.white to Theme.of(context).cardColor
    content = content.replace('Colors.white', 'Theme.of(context).cardColor')
    
    # 2. Fix SecureLogger.error(..., e, st) -> SecureLogger.error(..., error: e, stackTrace: st)
    content = re.sub(r'SecureLogger\.error\(([^,]+),\s*([^,]+),\s*([^)]+)\)', r'SecureLogger.error(\1, error: \2, stackTrace: \3)', content)
    
    # 3. Add import if SecureLogger is used but not imported
    if 'SecureLogger' in content and 'secure_logger.dart' not in content:
        content = "import 'package:hidden_gems_sl/core/utils/secure_logger.dart';\n" + content
        
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

def process_php(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    new_lines = []
    changed = False
    for line in lines:
        if 'env(' in line and 'config/' not in filepath.replace('\\', '/') and not line.strip().startswith('//'):
            line = re.sub(r"env\(['\"](.*?)['\"]\)", r"config('app.\1')", line)
            changed = True
        if ('dd(' in line or 'dump(' in line) and not line.strip().startswith('//'):
            line = "// " + line.lstrip()
            changed = True
        new_lines.append(line)
        
    if changed:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)

def process_python(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    new_lines = []
    changed = False
    for line in lines:
        if 'except Exception:' in line and not line.strip().startswith('#'):
            line = line.replace('except Exception:', 'except Exception as e:')
            changed = True
        if 'print(' in line and 'logger' not in line and not line.strip().startswith('#'):
            # Only replace if print is a function call
            if re.search(r'\bprint\(', line):
                line = re.sub(r'\bprint\(', 'logger.info(', line)
                changed = True
        new_lines.append(line)
        
    if changed:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)

def main():
    for bdir in ['lib', 'laravel-backend', 'backend']:
        if not os.path.exists(bdir):
            continue
        for root, dirs, files in os.walk(bdir):
            if any(x in root for x in ['venv', 'node_modules', '__pycache__', 'vendor', '.dart_tool']):
                continue
            for file in files:
                filepath = os.path.join(root, file)
                try:
                    if file.endswith('.dart'):
                        process_flutter(filepath)
                    elif file.endswith('.php'):
                        process_php(filepath)
                    elif file.endswith('.py'):
                        process_python(filepath)
                except Exception:
                    pass

if __name__ == "__main__":
    main()
