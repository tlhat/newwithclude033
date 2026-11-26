#!/usr/bin/env python3
"""Lists Arabic string literals shown through Text(...) so dialect packs can
translate them. Writes assets/dialects/egyptian.json (key = Egyptian text).
Run from the repo root: python3 tools/extract_ui_strings.py"""
import re, glob, json
pat = re.compile(r"Text\(\s*(?:'((?:[^'\\\n]|\\.)*)'|\"((?:[^\"\\\n]|\\.)*)\")")
ar = re.compile(r'[\u0600-\u06FF]')
keys = {}
for f in glob.glob('lib/**/*.dart', recursive=True):
    for m in pat.finditer(open(f, encoding='utf-8').read()):
        t = m.group(1) or m.group(2) or ''
        if ar.search(t) and '$' not in t:
            keys[t.replace("\\'", "'")] = t.replace("\\'", "'")
json.dump(dict(sorted(keys.items())), open('assets/dialects/egyptian.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
print(len(keys), 'strings')
