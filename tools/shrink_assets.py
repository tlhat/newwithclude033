#!/usr/bin/env python3
"""Shrink app assets so the release bundle fits Google Play limits.

  python tools/shrink_assets.py avatars      # 2048px PNG parts -> 1024px, 256-colour PNG
  python tools/shrink_assets.py audio        # speech mp3 -> mono 24 kHz 48 kbps
  python tools/shrink_assets.py all
  python tools/shrink_assets.py all --dry-run   # only prints the expected saving

Run it from the project root. File names and paths do not change, so no Dart
code needs to change. Originals are copied first to ../haneen_assets_backup/
(outside the project, so they are never bundled). Running it twice is safe.

Needs: pip install pillow   (avatars)   and   ffmpeg on PATH   (audio).
pngquant is used for avatars when installed, for slightly better quality.
"""
import argparse
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.getcwd()
BACKUP = os.path.abspath(os.path.join(ROOT, '..', 'haneen_assets_backup'))
AVATAR_SIZE = 1024
AUDIO_ARGS = ['-ac', '1', '-ar', '24000', '-b:a', '48k']


def files(folder, ext):
    base = os.path.join(ROOT, folder)
    for d, _, names in os.walk(base):
        for n in names:
            if n.lower().endswith(ext):
                yield os.path.join(d, n)


def backup(path):
    rel = os.path.relpath(path, ROOT)
    dst = os.path.join(BACKUP, rel)
    if not os.path.exists(dst):  # keep the very first original
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(path, dst)


def mb(n):
    return f'{n / 1048576:.1f} MB'


def avatars(dry):
    try:
        from PIL import Image
    except ImportError:
        sys.exit('Install Pillow first:  pip install pillow')
    pngquant = shutil.which('pngquant')
    before = after = 0
    items = list(files(os.path.join('assets', 'avatars'), '.png'))
    for i, f in enumerate(items, 1):
        size0 = os.path.getsize(f)
        before += size0
        im = Image.open(f)
        if im.width <= AVATAR_SIZE and size0 < 400_000:
            after += size0
            continue  # already small
        if dry:
            after += size0 // 30  # typical ratio seen on these art files
            continue
        backup(f)
        im = im.convert('RGBA')
        if im.width > AVATAR_SIZE:
            # Every part has the same square canvas, so scaling all of them
            # equally keeps the layers aligned.
            im = im.resize((AVATAR_SIZE, AVATAR_SIZE), Image.LANCZOS)
        tmp = f + '.tmp.png'
        im.save(tmp, optimize=True)
        if pngquant:
            subprocess.run([pngquant, '--quality=70-95', '--speed', '1',
                            '--force', '--output', f, tmp], check=False)
            if not os.path.exists(f) or os.path.getsize(f) == 0:
                shutil.copy2(tmp, f)
        else:
            q = im.quantize(colors=256, method=Image.Quantize.FASTOCTREE,
                            dither=Image.Dither.NONE)
            q.save(f, optimize=True)
        os.remove(tmp)
        after += os.path.getsize(f)
        if i % 20 == 0:
            print(f'  avatars {i}/{len(items)}')
    print(f'avatars: {mb(before)} -> {mb(after)}' + ('  (estimate)' if dry else ''))


def audio(dry):
    ffmpeg = shutil.which('ffmpeg')
    if not ffmpeg:
        sys.exit('ffmpeg not found. Install it and open a new terminal.')
    before = after = 0
    items = list(files(os.path.join('assets', 'audio'), '.mp3'))
    for i, f in enumerate(items, 1):
        size0 = os.path.getsize(f)
        before += size0
        if dry:
            after += int(size0 * 0.38)
            continue
        backup(f)
        fd, tmp = tempfile.mkstemp(suffix='.mp3')
        os.close(fd)
        r = subprocess.run([ffmpeg, '-y', '-loglevel', 'error', '-i', f,
                            '-map_metadata', '-1', *AUDIO_ARGS, tmp])
        if r.returncode == 0 and 0 < os.path.getsize(tmp) < size0:
            shutil.move(tmp, f)
        else:
            os.remove(tmp)  # already smaller or failed: keep the original
        after += os.path.getsize(f)
        if i % 200 == 0:
            print(f'  audio {i}/{len(items)}')
    print(f'audio ({len(items)} files): {mb(before)} -> {mb(after)}'
          + ('  (estimate)' if dry else ''))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('what', choices=['avatars', 'audio', 'all'])
    ap.add_argument('--dry-run', action='store_true')
    a = ap.parse_args()
    if not os.path.isdir(os.path.join(ROOT, 'assets')):
        sys.exit('Run this from the project root (the folder that has assets/).')
    if a.what in ('avatars', 'all'):
        avatars(a.dry_run)
    if a.what in ('audio', 'all'):
        audio(a.dry_run)
    if not a.dry_run:
        print(f'Originals saved in {BACKUP}')


if __name__ == '__main__':
    main()
