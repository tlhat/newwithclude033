#!/usr/bin/env python3
"""Builds assets/audio/audio_index.json and the pubspec asset folders.

Usage (from the project root, after copying the mp3 files into
assets/audio/<persona>/<feature>/<id>.mp3):

    python3 tools/build_audio_index.py tools/audio_manifest.json

audio_manifest.json is the list of clips: [{id, feature, persona, text}, ...].
Only clips whose mp3 file exists are indexed, so a partial set works.
"""
import hashlib, json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def normalize(t):
    for ch in ('«', '»', '"', '🎙️'):
        t = t.replace(ch, '')
    return re.sub(r'\s+', ' ', t).strip()

def key(persona, text):
    c = persona.strip().lower() + '|' + normalize(text)
    return hashlib.sha1(c.encode('utf-8')).hexdigest()[:12]

manifest = json.load(open(sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'tools', 'audio_manifest.json'), encoding='utf-8'))
index, dirs, missing = {}, set(), 0
for m in manifest:
    base = f"assets/audio/{m['persona']}/{m['feature']}/{m['id']}"
    rel = next((base + e for e in ('.ogg', '.mp3') if os.path.exists(os.path.join(ROOT, base + e))), None)
    if rel is None:
        missing += 1
        continue
    index[key(m['persona'], m['text'])] = rel
    dirs.add(os.path.dirname(rel) + '/')
with open(os.path.join(ROOT, 'assets/audio/audio_index.json'), 'w', encoding='utf-8') as f:
    json.dump(index, f, ensure_ascii=False, indent=0)

# Keep a marked block in pubspec.yaml with one line per audio folder.
pp = os.path.join(ROOT, 'pubspec.yaml')
s = open(pp, encoding='utf-8').read().replace('\r\n', '\n')
block = '    # audio-assets-begin\n    - assets/audio/audio_index.json\n' + ''.join(f'    - {d}\n' for d in sorted(dirs)) + '    # audio-assets-end\n'
if '# audio-assets-begin' in s:
    s = re.sub(r'    # audio-assets-begin\n.*?    # audio-assets-end\n', block, s, flags=re.S)
else:
    s = s.replace('  assets:\n', '  assets:\n' + block, 1)
open(pp, 'w', encoding='utf-8', newline='\n').write(s)
print(f'indexed {len(index)} clips, {missing} mp3 files not found, {len(dirs)} folders')
