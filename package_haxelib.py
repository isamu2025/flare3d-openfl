import zipfile
import os
import json

base_dir = os.path.dirname(os.path.abspath(__file__))
json_path = os.path.join(base_dir, 'haxelib.json')

if not os.path.exists(json_path):
    print('Error: haxelib.json not found!')
    exit(1)

with open(json_path, 'r', encoding='utf-8') as f:
    meta = json.load(f)

lib_name = meta.get('name', 'flare3d')
lib_version = meta.get('version', '1.0.0')
output_zip = os.path.join(base_dir, f'{lib_name}-{lib_version}.zip')

print(f'Packaging {lib_name} v{lib_version} for Haxelib...')

# Files and folders to include
root_files = ['haxelib.json', 'include.xml', 'README.md', 'LICENSE.md']
include_folders = ['src']

with zipfile.ZipFile(output_zip, 'w', zipfile.ZIP_DEFLATED) as z:
    # 1. Add root files
    for rf in root_files:
        src = os.path.join(base_dir, rf)
        if os.path.exists(src):
            z.write(src, rf)
            print(f' + {rf}')
        else:
            print(f' ! Warning: {rf} not found')

    # 2. Add source folders (relative paths starting from root)
    for folder in include_folders:
        folder_path = os.path.join(base_dir, folder)
        if os.path.exists(folder_path):
            for root, dirs, files in os.walk(folder_path):
                for file in files:
                    full_p = os.path.join(root, file)
                    rel_p = os.path.relpath(full_p, base_dir)
                    z.write(full_p, rel_p)
            print(f' + {folder}/ (recursive)')

size_kb = round(os.path.getsize(output_zip) / 1024, 2)
print(f'\nSuccess! Created: {output_zip}')
print(f'Package size: {size_kb} KB')
print(f'To publish to Haxelib, run:')
print(f'  haxelib submit {os.path.basename(output_zip)}')
