#!/usr/bin/env python3
"""Builds the spoken text ('spoken') for clips whose display/lookup text ('text') is hard to pronounce.

Lookup key stays the ORIGINAL text; only the recording uses 'spoken'. Rules:
 1. Letter names (MSA): a lone letter is spoken by its NAME, never by its sound ("ق" -> "قاف").
 2. Lexicon of risky MSA words -> full tashkeel (verified against standard Arabic orthography).
Colloquial words are NOT diacritized as MSA. Run: python3 tools/pronunciation_fix.py [--write]
"""
import json, re, sys, collections
NAMES = {'ا':'أَلِف','أ':'أَلِف','إ':'أَلِف','ب':'بَاء','ت':'تَاء','ث':'ثَاء','ج':'جِيم','ح':'حَاء','خ':'خَاء','د':'دَال','ذ':'ذَال','ر':'رَاء','ز':'زَاي','س':'سِين','ش':'شِين','ص':'صَاد','ض':'ضَاد','ط':'طَاء','ظ':'ظَاء','ع':'عَيْن','غ':'غَيْن','ف':'فَاء','ق':'قَاف','ك':'كَاف','ل':'لَام','م':'مِيم','ن':'نُون','ه':'هَاء','هـ':'هَاء','و':'وَاو','ي':'يَاء','ء':'هَمْزَة','ة':'تَاء مَرْبُوطَة'}
AR = '\u0621-\u064a'
DIAC = '\u064b-\u0652\u0670'
LONE = re.compile(rf'(?<![{AR}{DIAC}])(هـ|[{AR}])(?![{AR}{DIAC}])')

def letters(t):
    # drop the letter in brackets right after its name: "الباء (ب)" -> "الباء"
    t = re.sub(rf'(ال[{AR}]+)\s*\((?:هـ|[{AR}])\)', r'\1', t)
    def ctx_ok(m, s):
        ch = m.group(1)
        if ch != 'و':
            return True
        before = s[max(0, m.start()-12):m.start()]
        after = s[m.end():m.end()+3]
        return bool(re.search(r'(\(|«|حرف\s*|هو\s*|هي\s*|،\s*|:\s*)$', before)) and bool(re.match(r'\s*(\)|»|،|\.|؟|!|$)', after))
    out, last = [], 0
    for m in LONE.finditer(t):
        if not ctx_ok(m, t):
            continue
        ch = m.group(1)
        name = NAMES.get(ch)
        if not name:
            continue
        out.append(t[last:m.start()]); last = m.end()
        pre = t[:m.start()].rstrip().rstrip('(').rstrip()
        article = pre.endswith('حرف') or pre.endswith('بحرف') or pre.endswith('الحرف')
        if m.start() > 0 and t[m.start()-1] == '(' and t[m.end():m.end()+1] == ')':
            out[-1] = out[-1][:-1]; last = m.end()+1
        out.append(('ال' + name.replace('أَلِف','أَلِف') ) if article and ch not in 'ة' else name)
    out.append(t[last:])
    r = ''.join(out)
    # "ال" + vowelled name: join with sun/moon letters naturally ("الْقَاف" is read fine as "القاف")
    r = r.replace('الأَلِف','الأَلِف')
    return r

LEX = {
 'رقم':'رَقْم','الرقم':'الرَّقْم','مئة':'مِئَة','ومصور':'وَمُصَوَّر','مصور':'مُصَوَّر','أحسنت':'أَحْسَنْتَ','كلنا':'كُلُّنَا','بأس':'بَأْس',
 'ما شاء الله':'مَا شَاءَ اللَّه','الله':'اللَّه','ثم':'ثُمَّ','لقد':'لَقَدْ','ماذا':'مَاذَا','هذه':'هَذِهِ','هذا':'هَذَا','الذي':'الَّذِي','التي':'الَّتِي',
 'الآداب':'الآدَاب','الأبطال':'الأَبْطَال','الخارق':'الخَارِق','الخارقة':'الخَارِقَة','المرحلة':'المَرْحَلَة','المستوى':'المُسْتَوَى','الاختيارات':'الاخْتِيَارَات',
 'اختر':'اخْتَرْ','استمع':'اسْتَمِعْ','اجمع':'اجْمَعْ','أكمل':'أَكْمِلْ','ابدأ':'ابْدَأْ','الإجابة':'الإِجَابَة','إجابة':'إِجَابَة','الكلمة':'الكَلِمَة','كلمة':'كَلِمَة','لكلمة':'لِكَلِمَة',
 'الحرف':'الحَرْف','حرف':'حَرْف','بحرف':'بِحَرْف','الحروف':'الحُرُوف','القصة':'القِصَّة','الصورة':'الصُّورَة','الرمز':'الرَّمْز','لوحة':'لَوْحَة','اللوحة':'اللَّوْحَة',
 'ترتيب':'تَرْتِيب','خطوات':'خُطُوَات','مراحل':'مَرَاحِل','نمو':'نُمُوّ','غسل':'غَسْل','اليدين':'اليَدَيْن','الطعام':'الطَّعَام','وجبات':'وَجَبَات','النبتة':'النَّبْتَة',
 'ملك':'مَلِك','مخارج':'مَخَارِج','الفصيحة':'الفَصِيحَة','الفصاحة':'الفَصَاحَة','ينتمي':'يَنْتَمِي','البقية':'البَقِيَّة','المختلف':'المُخْتَلِف','الملاحظة':'المُلَاحَظَة',
 'الذاكرة':'الذَّاكِرَة','البصرية':'البَصَرِيَّة','المنطقي':'المَنْطِقِي','التفكير':'التَّفْكِير','أتقنت':'أَتْقَنْتَ','أتممت':'أَتْمَمْتَ','أنهيت':'أَنْهَيْتَ','أخرج':'أَخْرِجِ',
 'ببراعة':'بِبَرَاعَة','فخورة':'فَخُورَة','ذكية':'ذَكِيَّة','وصحيحة':'وَصَحِيحَة','محاولة':'مُحَاوَلَة','بالمحاولة':'بِالمُحَاوَلَة','شجاعة':'شُجَاعَة','وجميلة':'وَجَمِيلَة','تلميح':'تَلْمِيح',
 'لغز':'لُغْز','اللغز':'اللُّغْز','لعبة':'لُعْبَة','بهدوء':'بِهُدُوء','الهادئة':'الهَادِئَة','الهادئ':'الهَادِئ','ممتع':'مُمْتِع','وثقة':'وَثِقَة','التفاعلية':'التَّفَاعُلِيَّة','رحلتنا':'رِحْلَتُنَا',
 'بأسلوب':'بِأُسْلُوب','والآن':'وَالآنَ','تعلمناه':'تَعَلَّمْنَاه','لتعلم':'لِتَعَلُّم','نطبق':'نُطَبِّق','نبدأ':'نَبْدَأ','العائلة':'العَائِلَة','والأصدقاء':'وَالأَصْدِقَاء','الأمانة':'الأَمَانَة',
 'الصباح':'الصَّبَاح','المساء':'المَسَاء','الاستعداد':'الِاسْتِعْدَاد','الاسترخاء':'الِاسْتِرْخَاء','المسائي':'المَسَائِي','الوالدين':'الوَالِدَيْن','مراحل':'مَرَاحِل','عجائب':'عَجَائِب',
 'الغابة':'الغَابَة','السماء':'السَّمَاء','الأزهار':'الأَزْهَار','الأشكال':'الأَشْكَال','الرحيق':'الرَّحِيق','القضبان':'القُضْبَان','الحديدية':'الحَدِيدِيَّة','المسافرين':'المُسَافِرِين',
 'الأكسجين':'الأُكْسُجِين','الثمار':'الثِّمَار','الدفء':'الدِّفْء','البذرة':'البَذْرَة','الصابون':'الصَّابُون','التجفيف':'التَّجْفِيف','أسناننا':'أَسْنَانَنَا','العسل':'العَسَل',
}
def lex(t):
    for k in sorted(LEX, key=len, reverse=True):
        t = re.sub(rf'(?<![{AR}{DIAC}]){re.escape(k)}(?![{AR}{DIAC}])', LEX[k], t)
    return t

COLLOQUIAL = {'guide','hints','section_intro','companion','reactions','lesson_feedback','app','videos','brain_games','wrong_answer','hero_alerts','games_menu'}

def spoken(t, feature=''):
    t = letters(t)
    return t if feature in COLLOQUIAL else lex(t)

if __name__ == '__main__':
    rows = json.load(open('tools/audio_manifest.json', encoding='utf-8'))
    ch = []
    for r in rows:
        s = spoken(r['text'], r.get('feature',''))
        if s != r['text']:
            ch.append((r['id'], r['text'], s))
    print('clips changed', len(ch), 'of', len(rows))
    if '--write' in sys.argv:
        byid = {i: s for i, _, s in ch}
        for r in rows:
            if r['id'] in byid: r['spoken'] = byid[r['id']]
            else: r.pop('spoken', None)
        json.dump(rows, open('tools/audio_manifest.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
        open('/tmp/rerecord_all.tsv', 'w', encoding='utf-8').write(''.join(f"{i}\t{s}\n" for i, _, s in ch))
