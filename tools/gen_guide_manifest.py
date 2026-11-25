#!/usr/bin/env python3
"""Builds tools/guide_manifest.json and tools/guide_manifest.csv: every spoken
guidance line (game intros, question prompts, hints, right/wrong feedback,
bedtime pages, oral quiz). Run from the project root. Text must match the Dart
code exactly (lib/core/services/guide_voice.dart), so it is read from there.

Clip path: assets/audio/haneen/guide/<id>.mp3 (mono, low bitrate).
Then run: python3 tools/build_audio_index.py tools/audio_manifest_all.json
(or merge guide_manifest.json into audio_manifest.json first).
"""
import json, re, csv, os
R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
rd = lambda p: open(os.path.join(R, p), encoding='utf-8').read()
gv = rd('lib/core/services/guide_voice.dart')
out, seen = [], {}

def add(i, group, text):
    text = re.sub(r'\s+', ' ', re.sub(r"[^\u0600-\u06FFA-Za-z0-9\s.,\u060C\u061F?!:;()'\-]", '', text)).strip()
    if not text or text in seen:
        return
    seen[text] = i
    out.append({'id': i, 'feature': 'guide', 'persona': 'haneen', 'group': group, 'text': text})

def dart_list(name):
    body = re.search(name + r' = \[(.*?)\];', gv, re.S).group(1)
    return re.findall(r"'([^']*)'", body)

for n, t in enumerate(dart_list('rightLines')): add(f'gv_right_{n+1}', 'feedback_right', t)
for n, t in enumerate(dart_list('wrongLines')): add(f'gv_wrong_{n+1}', 'feedback_wrong', t)
wi = re.search(r'widgetIntro = \{(.*?)\};', gv, re.S).group(1)
for k, t in re.findall(r"'(\w+)': '([^']*)'", wi): add(f'gi_{k}', 'game_intro', t)
add('bed_start', 'story_intro', re.search(r"bedtimeStart = '([^']*)'", gv).group(1))
for s, title, hint in re.findall(r"ExerciseGameDef\('(\w+)', '([^']*)', '[^']*', '([^']*)'", rd('lib/features/exercises/game_catalog.dart')):
    add(f'gi_ex_{s}', 'game_intro', f'يلا نلعب {title}. ' + re.sub(r'[؟?!.]+$', '', hint) + '.')
w = rd('lib/features/brain_games/screens/world_games.dart')
bed = re.search(r'kBedtimeStories = \[(.*?)\n\];', w, re.S).group(1)
for si, story in enumerate(re.findall(r'\[(.*?)\n  \]', bed, re.S)):
    for pi, line in enumerate(re.findall(r"'([^']*)'", story)):
        add(f'bed_{si+1}_{pi+1}', 'story_page', line)
ex = json.load(open(os.path.join(R, 'assets/exercises/exercises_v1.json'), encoding='utf-8'))
plain = re.compile(r'^[\u0600-\u06FF0-9 ]+$')
for e in ex:
    i = e['id']
    add(f'ex_{i}_q', 'question_prompt', e.get('prompt', ''))
    for n, h in enumerate(e.get('hints', [])): add(f'ex_{i}_h{n}', 'hint', h)
    add(f'ex_{i}_ok', 'feedback_right', e.get('correct', ''))
    add(f'ex_{i}_no', 'feedback_wrong', e.get('wrong', ''))
    add(f'ex_{i}_why', 'explanation', e.get('explain', ''))
    d = e.get('data', {})
    if e['type'] in ('choice', 'blank'):
        opts = [str(x) for x in d.get('options', [])]
        q = e['prompt'] + (' ' + str(d.get('sentence')) if e['type'] == 'blank' else '')
        if opts and all(plain.match(o) for o in opts): q += ' الاختيارات: ' + '، '.join(opts) + '.'
        add(f'oral_{i}_q', 'oral_quiz_question', q)
        try: add(f'oral_{i}_a', 'oral_quiz_answer', 'الإجابة هي ' + opts[int(d['correct'])] + '.')
        except Exception: pass
    elif e['type'] == 'number':
        add(f'oral_{i}_q', 'oral_quiz_question', e['prompt'])
        add(f'oral_{i}_a', 'oral_quiz_answer', 'الإجابة هي ' + str(d.get('answer')) + '.')
json.dump(out, open(os.path.join(R, 'tools/guide_manifest.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
with open(os.path.join(R, 'tools/guide_manifest.csv'), 'w', encoding='utf-8-sig', newline='') as f:
    cw = csv.writer(f); cw.writerow(['id', 'group', 'text'])
    for m in out: cw.writerow([m['id'], m['group'], m['text']])
import collections
print(len(out), dict(collections.Counter(m['group'] for m in out)))
