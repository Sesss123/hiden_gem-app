import os
import re

backend_dir = r'c:\Users\sehas\.gemini\antigravity\scratch\hidden_gems_sl\backend'
for root, _, files in os.walk(backend_dir):
    for file in files:
        if file.endswith('.py'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Find bare `except:` and replace with `except Exception as e:`
            # This is a bit tricky if it has `except:\n  pass` etc.
            # I will use a simple regex replacing `except:` with `except Exception as e:`
            new_content = re.sub(r'\bexcept\s*:', 'except Exception as e:', content)
            
            # For logging: find `pass` under an except block and add a log if not there, but let's just do `logger.warning(f"Error: {e}")`
            
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
