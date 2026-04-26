import os
import re

base_dir = r"d:\Fitness App\Fitness-Tracker-app"
assets_dir = os.path.join(base_dir, "assets", "Fitness Journey")

# 1. Rename files and directories bottom-up
for root, dirs, files in os.walk(assets_dir, topdown=False):
    for name in files:
        if ' ' in name:
            old_path = os.path.join(root, name)
            new_name = name.replace(' ', '_')
            new_path = os.path.join(root, new_name)
            os.rename(old_path, new_path)
    
    for name in dirs:
        if ' ' in name:
            old_path = os.path.join(root, name)
            new_name = name.replace(' ', '_')
            new_path = os.path.join(root, new_name)
            os.rename(old_path, new_path)

# 2. Rename the base folder itself if needed
old_assets_dir = os.path.join(base_dir, "assets", "Fitness Journey")
new_assets_dir = os.path.join(base_dir, "assets", "Fitness_Journey")
if os.path.exists(old_assets_dir):
    os.rename(old_assets_dir, new_assets_dir)

# 3. Update pubspec.yaml
pubspec_path = os.path.join(base_dir, "pubspec.yaml")
with open(pubspec_path, 'r', encoding='utf-8') as f:
    pubspec_content = f.read()

def replace_spaces_in_asset_path(match):
    return match.group(0).replace(' ', '_')

# Find all lines starting with "- assets/Fitness Journey/" and replace spaces
new_pubspec_content = re.sub(r'-\s*assets/Fitness Journey/.*', replace_spaces_in_asset_path, pubspec_content)

with open(pubspec_path, 'w', encoding='utf-8') as f:
    f.write(new_pubspec_content)

# 4. Update video_mapping_service.dart
dart_path = os.path.join(base_dir, "lib", "services", "video_mapping_service.dart")
with open(dart_path, 'r', encoding='utf-8') as f:
    dart_content = f.read()

new_dart_content = re.sub(r"'assets/Fitness Journey/[^']+'", replace_spaces_in_asset_path, dart_content)

with open(dart_path, 'w', encoding='utf-8') as f:
    f.write(new_dart_content)

print("Renaming and updating complete!")
