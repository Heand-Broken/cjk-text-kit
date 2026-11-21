#!/usr/bin/env python3
"""Build the itch.io upload packages for CJK Text Kit.

Produces two archives in `dist/`:

* `cjk-text-kit-v1.0.0.zip` - the addon itself, ready to drop into a project.
* `cjk-text-kit-demo-v1.0.0.zip` - a runnable demo project, so a buyer can
  try the plugin before buying anything.

Usage:
    python tools/package_release.py
"""

from __future__ import annotations

import os
import shutil
import sys
import tempfile
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIST = os.path.join(ROOT, "dist")
VERSION = "1.0.0"

# Files that must never end up in a release archive.
#
# `.uid` files are kept on purpose: since Godot 4.4 they hold the stable
# resource id of a script, and the official plugins ship them. `.import`
# files are excluded because they are local import artifacts that point at
# absolute paths of the machine that built them.
EXCLUDED_SUFFIXES = (".import",)
EXCLUDED_DIRS = {".godot", "__pycache__", ".git", "frames"}


def is_excluded(name: str) -> bool:
    return name.endswith(EXCLUDED_SUFFIXES)


def add_tree(archive: zipfile.ZipFile, source: str, prefix: str = "") -> int:
    """Adds every file under `source` to `archive`, keeping the layout."""
    added = 0
    for root, dirs, files in os.walk(source):
        dirs[:] = sorted(d for d in dirs if d not in EXCLUDED_DIRS)
        for name in sorted(files):
            if is_excluded(name):
                continue
            path = os.path.join(root, name)
            relative = os.path.relpath(path, source).replace(os.sep, "/")
            archive.write(path, os.path.join(prefix, relative).replace(os.sep, "/"))
            added += 1
    return added


def build_plugin_zip(path: str) -> int:
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        return add_tree(archive, os.path.join(ROOT, "addons"), "addons")


def build_demo_zip(path: str) -> int:
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        archive.write(os.path.join(ROOT, "project.godot"), "project.godot")
        added = add_tree(archive, os.path.join(ROOT, "addons"), "addons")
        added += add_tree(archive, os.path.join(ROOT, "demo"), "demo")
        added += add_tree(archive, os.path.join(ROOT, "tests"), "tests")
        for extra in ("README.md", "README.zh-CN.md"):
            candidate = os.path.join(ROOT, extra)
            if os.path.exists(candidate):
                archive.write(candidate, extra)
                added += 1
        return added


def report(path: str, count: int) -> None:
    size_kb = os.path.getsize(path) / 1024.0
    print("  %-34s %3d files  %8.1f KB" % (os.path.basename(path), count, size_kb))


def main() -> int:
    os.makedirs(DIST, exist_ok=True)
    print("Building release packages...")

    plugin = os.path.join(DIST, "cjk-text-kit-v%s.zip" % VERSION)
    demo = os.path.join(DIST, "cjk-text-kit-demo-v%s.zip" % VERSION)

    report(plugin, build_plugin_zip(plugin))
    report(demo, build_demo_zip(demo))
    print("Done. Upload both files with itch/publish.ps1 or itch/publish.sh.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
