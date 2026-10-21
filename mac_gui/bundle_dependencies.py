#!/usr/bin/env python3
"""
bundle_dependencies.py
Copies bulk_extractor CLI and all dependent non-system dynamic libraries (.dylib)
into a macOS App bundle, fixes rpaths and dynamic linker paths using install_name_tool,
and codesigns all components.
"""

import sys
import os
import shutil
import subprocess
import re

def get_dependencies(binary_path):
    """Returns non-system dylib paths referenced by a binary or dylib."""
    try:
        out = subprocess.check_output(['otool', '-L', binary_path]).decode('utf-8', errors='ignore')
    except subprocess.CalledProcessError:
        return []

    deps = []
    for line in out.splitlines()[1:]:
        m = re.match(r'^\s*([^\s]+)', line)
        if m:
            path = m.group(1)
            # Skip system libraries and already-relocated @ paths
            if not path.startswith('/System') and not path.startswith('/usr/lib') and not path.startswith('@'):
                deps.append(path)
    return deps

def bundle_app(app_path, cli_binary_path):
    print(f"[*] Packaging standalone app bundle: {app_path}")
    print(f"[*] Sourcing bulk_extractor binary: {cli_binary_path}")

    helpers_dir = os.path.join(app_path, "Contents", "Helpers")
    frameworks_dir = os.path.join(app_path, "Contents", "Frameworks")
    macos_dir = os.path.join(app_path, "Contents", "MacOS")

    os.makedirs(helpers_dir, exist_ok=True)
    os.makedirs(frameworks_dir, exist_ok=True)

    # 1. Copy CLI binary
    dest_cli = os.path.join(helpers_dir, "bulk_extractor")
    shutil.copy2(cli_binary_path, dest_cli)
    os.chmod(dest_cli, 0o755)

    # 2. Recursively find all dependent dylibs
    seen_deps = {} # original_path -> basename
    to_visit = [dest_cli]

    while to_visit:
        current = to_visit.pop(0)
        for dep in get_dependencies(current):
            if dep not in seen_deps:
                real_dep = os.path.realpath(dep)
                if not os.path.exists(real_dep):
                    print(f"[-] Warning: Dependency not found on disk: {dep}")
                    continue
                base_name = os.path.basename(dep)
                dest_dylib = os.path.join(frameworks_dir, base_name)
                if not os.path.exists(dest_dylib):
                    shutil.copy2(real_dep, dest_dylib)
                    os.chmod(dest_dylib, 0o755)
                seen_deps[dep] = base_name
                to_visit.append(dest_dylib)

    print(f"[+] Discovered and copied {len(seen_deps)} dynamic libraries into Contents/Frameworks")

    # 3. Build install_name_tool change arguments
    change_args = []
    for old_path, base_name in seen_deps.items():
        change_args.extend(['-change', old_path, f'@rpath/{base_name}'])

    # 4. Patch Frameworks (dylibs)
    for base_name in os.listdir(frameworks_dir):
        dylib_path = os.path.join(frameworks_dir, base_name)
        if not os.path.isfile(dylib_path):
            continue
        patch_cmd = ['install_name_tool', '-id', f'@rpath/{base_name}'] + change_args + [dylib_path]
        subprocess.run(patch_cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(['codesign', '-s', '-', '--force', dylib_path], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # 5. Patch bulk_extractor CLI helper
    cli_cmd = ['install_name_tool', '-add_rpath', '@loader_path/../Frameworks'] + change_args + [dest_cli]
    subprocess.run(cli_cmd, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(['codesign', '-s', '-', '--force', dest_cli], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # 6. Patch main App binary (if present)
    for exe in os.listdir(macos_dir):
        exe_path = os.path.join(macos_dir, exe)
        if os.path.isfile(exe_path) and os.access(exe_path, os.X_OK):
            app_cmd = ['install_name_tool', '-add_rpath', '@executable_path/../Frameworks', exe_path]
            subprocess.run(app_cmd, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(['codesign', '-s', '-', '--force', exe_path], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # 7. Final App signature
    subprocess.run(['codesign', '-s', '-', '--force', '--deep', app_path], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # 8. Verification
    test_run = subprocess.run([dest_cli, '-H'], capture_output=True, text=True)
    if "Scanner Name:" in test_run.stdout or test_run.returncode in (0, 2):
        print("[✓] Bundled bulk_extractor verified successfully inside App bundle!")
    else:
        print(f"[-] Warning: Test run of bundled binary exited with code {test_run.returncode}")
        print(test_run.stderr)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: bundle_dependencies.py <BulkExtractor.app> <path/to/bulk_extractor>")
        sys.exit(1)
    bundle_app(sys.argv[1], sys.argv[2])
