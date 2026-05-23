import os
import glob

screens_dir = r"c:\Users\Kean\OneDrive\Desktop\rockies-fitness-tracker\Fitness-Tracker-app\lib\screens"

count = 0
for filepath in glob.glob(os.path.join(screens_dir, "*.dart")):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if "appBar: AppBar(" in content:
        lines = content.split('\n')
        new_lines = []
        for i, line in enumerate(lines):
            new_lines.append(line)
            if "appBar: AppBar(" in line:
                has_toolbar_height = False
                # Check up to 5 lines ahead
                for j in range(1, 6):
                    if i + j < len(lines) and "toolbarHeight" in lines[i+j]:
                        has_toolbar_height = True
                        break
                
                if not has_toolbar_height:
                    indent = line[:len(line) - len(line.lstrip())]
                    new_lines.append(indent + "  toolbarHeight: 80,")
        
        new_content = '\n'.join(new_lines)
        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            count += 1
            print(f"Updated {os.path.basename(filepath)}")

print(f"Total files updated: {count}")
